#!/usr/bin/env bash

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
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

SCRIPT_LIST="
    amboss-ping
    channelbalance
    feereport
    prune-protector
    routing-summary
    random-traffic-gen
    walletbalance
"

for script in $SCRIPT_LIST; do
    echo -n "Installing cln-$script..."
    $sudo install -p -t "$PREFIX" ./cln-$script.sh
    $sudo ln -f -s "$PREFIX/cln-$script.sh" /usr/local/bin/cln-$script
    echo ""
done

echo -n "Creating cln-uninstall..."
$sudo bash -c 'cat <<EOF > '"$PREFIX/cln-uninstall.sh"'
#!/usr/bin/env bash
if [[ "\$(whoami)" == "root" ]]; then
    sudo=""
else
    sudo="sudo"
fi
PREFIX="'"$PREFIX"'"
SCRIPT_LIST="'"$SCRIPT_LIST"'"
read -n 1 -p "This will uninstall cln-scripts from \$PREFIX. Are you sure? (y/N) "
echo ""
if [[ \${REPLY} =~ y|Y ]]; then
    for script in \$SCRIPT_LIST; do
        echo -n "Uninstalling cln-\$script..."
        \$sudo unlink /usr/local/bin/cln-\$script
        \$sudo rm -f "\$PREFIX/cln-\$script.sh"
	echo ""
    done
    echo "Clean up rest..."
    \$sudo rm -f "\$PREFIX/inc.common.sh"
    \$sudo unlink /usr/local/sbin/cln-uninstall
    \$sudo rm -f "\$PREFIX/cln-uninstall.sh"
    \$sudo rmdir "\$PREFIX" 2> /dev/null
    echo "Done."
fi
EOF'
$sudo chmod +x "$PREFIX/cln-uninstall.sh"
$sudo ln -f -s "$PREFIX/cln-uninstall.sh" /usr/local/sbin/cln-uninstall

echo "Done."
