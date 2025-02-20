#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Compute and display the wallet's current balance."
    echo "Usage: $(basename "$0")"
    exit
fi

# Note that unconfirmed_balance will always be 0 for now, even if there
# is pending unconfirmed tx in mempool.
# See <https://github.com/ElementsProject/lightning/issues/2104>.

confirmed_balance="0"
unconfirmed_balance="0"
locked_balance="0"
outputs="$(lightning-cli listfunds | jq ".outputs")"
# lightning-cli listfunds | jq ".outputs" | jq -r ".[].status"
readarray -t output_statuses < <(jq -r ".[].status" <<< "$outputs")
readarray -t output_amount_msat < <(jq -r ".[].amount_msat" <<< "$outputs")
readarray -t output_reserved < <(jq -r ".[].reserved" <<< "$outputs")
for i in $(seq 0 $(( ${#output_statuses[@]} - 1 )) ); do
    if [[ "${output_reserved[$i]}" != "true" ]]; then
        if [[ "${output_statuses[$i]}" == "confirmed" ]]; then
            confirmed_balance=$((confirmed_balance + ${output_amount_msat[$i]}))
        elif [[ "${output_statuses[$i]}" == "unconfirmed" ]]; then
            unconfirmed_balance=$((unconfirmed_balance + ${output_amount_msat[$i]}))
        fi
    else
        locked_balance=$((locked_balance + ${output_amount_msat[$i]}))
    fi
done
confirmed_balance=$((confirmed_balance / 1000))
unconfirmed_balance=$((unconfirmed_balance / 1000))
total_balance=$((confirmed_balance + unconfirmed_balance))

echo "{
    \"total_balance\": $total_balance,
    \"confirmed_balance\": $confirmed_balance,
    \"unconfirmed_balance\": $unconfirmed_balance,
    \"locked_balance\": $locked_balance
}"
