#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Returns the sum of the total available channel balance across all open channels."
    echo "Usage: $(basename "$0")"
    exit
fi

channels="$(lightning-cli listfunds | jq ".channels[]")"
readarray -t channel_states < <(jq -r ".state" <<< "$channels")
readarray -t channel_our_msat < <(jq -r ".our_amount_msat" <<< "$channels")
readarray -t channel_total_msat < <(jq -r ".amount_msat" <<< "$channels")

local_balance_msat="0"
remote_balance_msat="0"
unsettled_local_balance_msat="0"
unsettled_remote_balance_msat="0"
pending_open_local_balance_msat="0"
pending_open_remote_balance_msat="0"
for i in $(seq 0 $(( ${#channel_states[@]} - 1 )) ); do
    this_our_msat="${channel_our_msat[$i]}"
    this_our_msat=${this_our_msat%msat}
    this_total_msat="${channel_total_msat[$i]}"
    this_total_msat=${this_total_msat%msat}
    this_remote_msat=$(( this_total_msat - this_our_msat ))
    if [[ "${channel_states[$i]}" == "CHANNELD_NORMAL" ]]; then
        local_balance_msat=$(( local_balance_msat + this_our_msat ))
        remote_balance_msat=$(( remote_balance_msat + this_remote_msat ))
    elif
        [[ "${channel_states[$i]}" == "OPENINGD" ]] ||
        [[ "${channel_states[$i]}" == "CHANNELD_AWAITING_LOCKIN" ]] ||
        [[ "${channel_states[$i]}" == "DUALOPEND_OPEN_INIT" ]] ||
        [[ "${channel_states[$i]}" == "DUALOPEND_AWAITING_LOCKIN" ]]
    then
        pending_open_local_balance_msat=$(( pending_open_local_balance_msat + this_our_msat ))
        pending_open_remote_balance_msat=$(( pending_open_remote_balance_msat + this_remote_msat ))
    else
        unsettled_local_balance_msat=$(( unsettled_local_balance_msat + this_our_msat ))
        unsettled_remote_balance_msat=$(( unsettled_remote_balance_msat + this_remote_msat ))
    fi
done

# LND has also "balance" and "pending_open_balance", but they are deprecated.
# https://github.com/lightningnetwork/lnd/blob/8109c9ccf1e41b32234b2372d09aa83b20d65d63/lnrpc/lightning.proto#L2562
jq -M <<< "
{
    \"local_balance\": {
        \"sat\": \"$(( local_balance_msat / 1000 ))\",
        \"msat\": \"$local_balance_msat\"
    },
    \"remote_balance\": {
        \"sat\": \"$(( remote_balance_msat / 1000 ))\",
        \"msat\": \"$remote_balance_msat\"
    },
    \"unsettled_local_balance\": {
        \"sat\": \"$(( unsettled_local_balance_msat / 1000 ))\",
        \"msat\": \"$unsettled_local_balance_msat\"
    },
    \"unsettled_remote_balance\": {
        \"sat\": \"$(( unsettled_remote_balance_msat / 1000 ))\",
        \"msat\": \"$unsettled_remote_balance_msat\"
    },
    \"pending_open_local_balance\": {
        \"sat\": \"$(( pending_open_local_balance_msat / 1000 ))\",
        \"msat\": \"$pending_open_local_balance_msat\"
    },
    \"pending_open_remote_balance\": {
        \"sat\": \"$(( pending_open_remote_balance_msat / 1000 ))\",
        \"msat\": \"$pending_open_remote_balance_msat\"
    }
}
"
