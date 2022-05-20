#!/usr/bin/env bats

. "../inc.common.sh"

@test "CLN short channel id to LND short channel id" {
    [[ $(cl_to_lnd_scid "734778x1235x0") == "807896954914930688" ]]
}

@test "LND short channel id to CLN short channel id" {
    [[ $(lnd_to_cl_scid "807896954914930688") == "734778x1235x0" ]]
}
