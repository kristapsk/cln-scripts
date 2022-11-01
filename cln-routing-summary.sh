#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Display routing summary for a given period."
    echo "Usage: $(basename "$0") [start_date [end_date]]"
    exit
fi

if [[ -n "$1" ]]; then
    start_date="$(date -d "$1" +"%s")"
else
    start_date="0"
fi
if [[ -n "$2" ]]; then
    end_date="$(date -d "$2" +"%s")"
else
    end_date="$(date +"%s")"
fi

# Very old forwards will not have "resolved_time", but we want to include
# them anyay if start_date is 0.
if (( start_date == 0 )); then
    resolved_time_filter=".resolved_time <= $end_date"
else
    resolved_time_filter=".resolved_time >= $start_date and \
        .resolved_time <= $end_date"
fi

forwards="$(lightning-cli listforwards settled | \
    jq "[.forwards[] | select($resolved_time_filter)]")"
readarray -t fwd_out_msatoshis < <(jq ".[].out_msatoshi" <<< "$forwards")
readarray -t fwd_fees < <(jq ".[].fee" <<< "$forwards")
forwarded_sum="0"
fee_sum="0"
for i in $(seq 0 $(( ${#fwd_fees[@]} - 1 )) ); do
    forwarded_sum=$((forwarded_sum += ${fwd_out_msatoshis[$i]}))
    fee_sum=$((fee_sum += ${fwd_fees[$i]}))
done

jq -M <<< "{
    \"period_start\": $start_date,
    \"period_end\": $end_date,
    \"num_forwards\": $(jq -r "length" <<< "$forwards"),
    \"forwarded_sum\": $(( forwarded_sum / 1000 )),
    \"fee_sum\": $(( fee_sum / 1000 ))
}"
