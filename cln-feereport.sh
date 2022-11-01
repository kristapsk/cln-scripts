#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Display the current fee policies of all active channels."
    echo "Usage: $(basename "$0")"
    exit
fi

our_nodeid="$(lightning-cli getinfo | jq -r ".id")"

# shellcheck disable=SC1091
# shellcheck source=./inc.common.sh
. "$(dirname "$(readlink -m "$0")")/inc.common.sh"

channels="$(lightning-cli listfunds | \
    jq '.channels[] | select(.state=="CHANNELD_NORMAL")')"
readarray -t short_channel_ids < <(jq -r ".short_channel_id" <<< "$channels")
readarray -t funding_txids < <(jq -r ".funding_txid" <<< "$channels")
readarray -t funding_outputs < <(jq -r ".funding_output" <<< "$channels")

channel_fees=""
needs_comma=""
for i in $(seq 0 $(( ${#short_channel_ids[@]} - 1 )) ); do
    channel_detail="$(lightning-cli listchannels "${short_channel_ids[$i]}" | \
        jq ".channels")"
    readarray -t detail_sources < <(jq -r ".[].source" <<< "$channel_detail")
    readarray -t detail_base_fee_msat < <(jq -r ".[].base_fee_millisatoshi" \
        <<< "$channel_detail")
    readarray -t detail_fee_per_mil < <(jq -r ".[].fee_per_millionth" \
        <<< "$channel_detail")
    for j in $(seq 0 $(( ${#detail_sources[@]} - 1 )) ); do
        if [[ "${detail_sources[$j]}" == "$our_nodeid" ]]; then
            if [[ "$needs_comma" == "1" ]]; then
                channel_fees="$channel_fees,"
            fi
            channel_fee="{
                \"chan_id\": \"$(cl_to_lnd_scid "${short_channel_ids[$i]}")\",
                \"cln_chan_id\": \"${short_channel_ids[$i]}\",
                \"channel_point\":
                    \"${funding_txids[$i]}:${funding_outputs[$i]}\",
                \"base_fee_msat\": \"${detail_base_fee_msat[$j]}\",
                \"fee_per_mil\": \"${detail_fee_per_mil[$j]}\",
                \"fee_rate\":
                    $(bc <<< "scale=6; ${detail_fee_per_mil[$j]} / 1000000")
            }"
            channel_fees="$channel_fees$channel_fee"
            needs_comma="1"
            break
        fi
    done
done

day_ago="$(date -d "day ago" +"%s")"
week_ago="$(date -d "week ago" +"%s")"
month_ago="$(date -d "month ago" +"%s")"
forwards="$(lightning-cli listforwards settled | \
    jq ".forwards[] | select(.resolved_time > $month_ago)")"
readarray -t fwd_fees < <(jq ".fee" <<< "$forwards")
readarray -t fwd_times < <(jq -r ".resolved_time | floor" <<< "$forwards")
day_fee_sum="0"
week_fee_sum="0"
month_fee_sum="0"
for i in $(seq 0 $(( ${#fwd_fees[@]} - 1 )) ); do
    if (( ${fwd_times[$i]} > month_ago )); then
        month_fee_sum=$((month_fee_sum + ${fwd_fees[$i]}))
        if (( ${fwd_times[$i]} > week_ago )); then
            week_fee_sum=$((week_fee_sum + ${fwd_fees[$i]}))
            if (( ${fwd_times[$i]} > day_ago )); then
                day_fee_sum=$((day_fee_sum + ${fwd_fees[$i]}))
            fi
        fi
    fi
done

fees_collected_msat="$(lightning-cli getinfo | jq -r ".fees_collected_msat")"
fees_collected_msat=${fees_collected_msat%msat}

jq -M <<< "{
    \"channel_fees\": [ $channel_fees ],
    \"day_fee_sum\": \"$(( day_fee_sum / 1000 ))\",
    \"week_fee_sum\": \"$(( week_fee_sum / 1000 ))\",
    \"month_fee_sum\": \"$(( month_fee_sum / 1000 ))\",
    \"total_fee_sum\": \"$(( fees_collected_msat / 1000 ))\"
}"
