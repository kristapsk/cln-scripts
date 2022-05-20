#!/usr/bin/env bash

if [[ "$1" == "-h" ]] | [[ "$1" == "--help" ]]; then
    echo "Installs CLN scripts."
    echo "Usage: $(basename "$0")"
    exit
fi

PREFIX="/opt/cln-scripts"

if [[ "$(whoami)" == "root" ]]; then
    sudo=""
else
    sudo="sudo"
fi

cd "$(dirname "$0")" || exit 1

$sudo mkdir -p "$PREFIX"

echo -n "Installing inc.common.sh..."
$sudo install -p -t "$PREFIX" -m 644 ./inc.common.sh
echo ""

for script in \
    channelbalance \
    feereport \
    prune-protector \
    random-traffic-gen \
    walletbalance
do
    echo -n "Installing cln-$script..."
    $sudo install -p -t "$PREFIX" ./cln-$script.sh
    $sudo ln -f -s "$PREFIX/cln-$script.sh" /usr/bin/cln-$script
    echo ""
done

echo "Done."
