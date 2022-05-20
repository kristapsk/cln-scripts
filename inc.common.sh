# shellcheck disable=SC2148

# https://bitcoin.stackexchange.com/a/79427
cl_to_lnd_scid()
{
    IFS="x" read -r -a s <<< "$1"
    echo $(( (s[0] << 40) | (s[1] << 16) | s[2] ))
}

lnd_to_cl_scid()
{
	echo "$(( "$1" >> 40 ))x$(( "$1" >> 16 & 0xFFFFFF ))x$(( "$1" & 0xFFFF ))"
}

