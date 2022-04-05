# cln-scripts

Various shell scripts for [CLN (Core Lightning / c-lightning)](https://github.com/ElementsProject/lightning).

Dependencies: `bash`, `lightning-cli` (comes with CLN), [`jq`](https://github.com/stedolan/jq).

All scripts support `-h`/`--help` for usage information.

| Script | Description |
| --- | --- |
| `cln-random-traffic-gen.sh` | Generate random (decoy) LN traffic between you and your peers to fight traffic analysis. Has lock protection against running multiple instances at the same time so can safely be just added to crontab. |
| `cln-walletbalance.sh` | Emulates `lncli walletbalance` of LND for CLN. Compute and display the onchain wallet's current balance. |

## Support

[![tippin.me](https://badgen.net/badge/%E2%9A%A1%EF%B8%8Ftippin.me/@kristapsk/F0918E)](https://tippin.me/@kristapsk)

If you want to support my work on this project and other free software (I am also maintainer of [JoinMarket](https://github.com/JoinMarket-Org/joinmarket-clientserver) and do other Bitcoin stuff), you can send some sats (Bitcoin) either [here](https://donate.kristapsk.lv/) (that's my self-hosted [SatSale](https://github.com/nickfarrow/SatSale) instance) or by using [tippin.me](https://tippin.me/@kristapsk).
