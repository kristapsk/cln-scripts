#!/usr/bin/env bash
# Based on https://gist.github.com/swissrouting/111d4a615d670ddf8d11eaa8a60eacca
# Docs: https://docs.amboss.space/api/monitoring/health-checks

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Send node health check ping to Amboss."
    echo "Usage: $(basename "$0") [sleeptime]"
    echo "Where:"
    echo "  sleeptime	- sleep time between pings (default: 30)"
    exit
fi

API_URL="https://api.amboss.space/graphql"

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
	sleeptime="$1"
else
	sleeptime="30"
fi

while :; do
    NOW="$(date -u +%Y-%m-%dT%H:%M:%S%z)"
    echo -n "[$NOW] "
    SIGNATURE="$(lightning-cli signmessage "$NOW" | jq -r .zbase)"
    if [[ -z "$SIGNATURE" ]]; then
        echo "Failed to sign message with CLN, aborting!"
        kill $$
    fi
    PAYLOAD="$(jq -M <<< "{
        \"query\": \"mutation HealthCheck(\$signature: String!, \$timestamp: String!) { healthCheck(signature: \$signature, timestamp: \$timestamp) }\",
        \"variables\": {
            \"signature\": \"$SIGNATURE\",
            \"timestamp\": \"$NOW\"
        }
    }")"
    echo "$API_URL $SIGNATURE"
    RESPONSE="$(echo "$PAYLOAD" | curl -sSf --data-binary @- \
        -H "Content-Type: application/json" -X POST "$API_URL")"
    NOW="$(date -u +%Y-%m-%dT%H:%M:%S%z)"
    echo -n "[$NOW] "
    jq -Mc <<< "$RESPONSE"
    sleep "$sleeptime"
done
