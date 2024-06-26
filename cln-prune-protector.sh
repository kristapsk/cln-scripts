#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Protect CLN against Bitcoin Core pruning too much."
    echo "When CLN is not running or lags too many blocks behind, "
    echo " P2P network traffic of Bitcoin Core is temporary disabled."
    echo "Usage: $(basename "$0") [numblocks [checktime]]"
    echo "Where:"
    echo "  numblocks   - maximum number of blocks to allow lag behind (default: 500)"
    echo "  checktime   - interval at which to do the checks (default: 60s)"
    exit
fi

lockdir="/tmp/$(basename "$0").lock"
if mkdir "$lockdir" 2> /dev/null; then
    trap 'rm -rf "$lockdir"' 0
    trap "exit 2" 1 2 3 15
else
    #echo "Already running (pid $(cat "$lockdir"/pid))"
    exit 1
fi
echo "$$" > "$lockdir"/pid 2> /dev/null || exit 2

if [[ -n "$1" ]]; then
    check_numblocks="$1"
else
    check_numblocks="500"
fi
if [[ -n "$2" ]]; then
    check_interval="$2"
else
    check_interval="10s"
fi

# shellcheck disable=SC1091
# shellcheck source=./inc.common.sh
. "$(dirname "$(readlink -m "$0")")/inc.common.sh"

log_with_date "Starting"
log_with_date "check_numblocks = $check_numblocks, check_interval = $check_interval"

if ! bitcoin-cli echo > /dev/null 2>&1; then
    log_with_date "Bitcoin Core not running, exiting."
    exit 1
fi

if ! lightning-cli getinfo > /dev/null 2>&1; then
    log_with_date "CLN not running, exiting."
    exit 1
fi

bitcoind_networkactive="$(bitcoin-cli getnetworkinfo | \
    jq -r ".networkactive")"

bitcoind_setnetworkactive()
{
    if [[ "$1" != "$bitcoind_networkactive" ]]; then
        echo -n "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] "
        bitcoind_networkactive="$(bitcoin-cli setnetworkactive "$1")"
        log_with_date "bitcoin-cli setnetworkactive $1 (because $2): $bitcoind_networkactive"
    fi
}

while :; do
    if ! btc_bh="$(bitcoin-cli getblockcount 2> /dev/null)"; then
        log_with_date "Bitcoin Core not running."
    elif wbh_res="$(lightning-cli waitblockheight 0 2> /dev/null)"; then
        cln_bh="$(jq -r ".blockheight" <<< "$wbh_res")"
        log_with_date "bitcoind blockheight $btc_bh, cln blockheigt $cln_bh (diff = $(( btc_bh - cln_bh )))"
        if (( $(( btc_bh - cln_bh )) > check_numblocks )); then
            bitcoind_setnetworkactive false \
                "$btc_bh - $cln_bh > $check_numblocks"
        elif (( $(( btc_bh - cln_bh )) <= $(( check_numblocks / 2 )) )); then
            bitcoind_setnetworkactive true \
                "$btc_bh - $cln_bh <= $(( check_numblocks / 2 ))"
        fi
    else
        bitcoind_setnetworkactive false "CLN not running"
    fi
    log_with_date "Sleeping for $check_interval"
    sleep "$check_interval"
done
