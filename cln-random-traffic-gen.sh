#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Generate random (decoy) LN traffic between you and your peers to fight traffic analysis."
    echo "Usage: $(basename "$0") [sleeptime_min [sleeptime_max]]"
    echo "Where:"
    echo "  sleeptime_min   - minimum sleep time between ping loop iterations (default: 10)"
    echo "  sleeptime_max   - maximum sleep time between ping loop iterations (default: 600)"
    exit
fi

lockdir="/tmp/$(basename "$0").lock"
if mkdir "$lockdir" 2> /dev/null; then
    trap 'rm -rf "$lockdir"' 0
    trap "exit 2" 1 2 3 15
else
    echo "Already running (pid $(cat "$lockdir"/pid))"
    exit 1
fi
echo "$$" > "$lockdir"/pid 2> /dev/null || exit 2

if [[ -n "$1" ]]; then
    sleeptime_min="$1"
else
    sleeptime_min="10"
fi
if [[ -n "$2" ]]; then
    sleeptime_max="$2"
else
    sleeptime_max="600"
fi
sleeptime_diff="$(( sleeptime_max - sleeptime_min ))"

while :; do
    lightning-cli listpeers | jq -r ".peers[].id" | while read -r node_id; do
        # Each peer has 50% probability of being pinged during each ping loop.
        if [[ $((RANDOM % 2)) != 0 ]]; then
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Pinging $node_id"
            lightning-cli ping "$node_id" $((RANDOM % 65530)) $((RANDOM % 65530))
        fi
    done
    sleeptime="$(( (RANDOM % sleeptime_diff) + sleeptime_min ))"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] sleeping for $sleeptime secs..."
    sleep "$sleeptime"
done
