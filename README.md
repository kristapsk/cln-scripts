# cln-scripts

Various shell scripts for [CLN (Core Lightning / c-lightning)](https://github.com/ElementsProject/lightning). I also have [some scripts for Bitcoin Core](https://github.com/kristapsk/bitcoin-scripts).

## Installation

Dependencies: `bash`, `lightning-cli` (comes with CLN), `bc`, [`jq`](https://github.com/stedolan/jq).

Gentoo Linux users can use [my portage overlay](https://github.com/kristapsk/portage-overlay):
```sh
# layman -o https://raw.github.com/kristapsk/portage-overlay/master/overlay.xml -L -a kristapsk
# emerge -av cln-scripts
```

Otherwise, use provided `install.sh` script, which will install everything in `/opt/cln-scripts` with symlinks in `/usr/local/bin` (so that they are on `PATH`).

## Usage

All scripts support `-h`/`--help` for usage information.

| Script | Description |
| --- | --- |
| `cln-amboss-ping` | Send node health check ping to Amboss, see [docs](https://docs.amboss.space/api/monitoring/health-checks). |
| `cln-channelbalance` | Returns the sum of the total available channel balance across all open channels, like `lncli channelbalance` of LND. |
| `cln-feereport` | Display the current fee policies of all active channels, like `lncli feereport` of LND. |
| `cln-prune-protector` | Protect CLN against Bitcoin Core pruning too much. |
| `cln-random-traffic-gen` | Generate random (decoy) LN traffic between you and your peers to fight traffic analysis. Has lock protection against running multiple instances at the same time so can safely be just added to crontab. |
| `cln-walletbalance` | Compute and display the onchain wallet's current balance, like `lncli walletbalance` of LND. |

## Support

[![tippin.me](https://badgen.net/badge/%E2%9A%A1%EF%B8%8Ftippin.me/@kristapsk/F0918E)](https://tippin.me/@kristapsk)

If you want to support my work on this project and other free software (I am also maintainer of [JoinMarket](https://github.com/JoinMarket-Org/joinmarket-clientserver) and do other Bitcoin stuff), you can send some sats (Bitcoin) either [here](https://donate.kristapsk.lv/) (that's my self-hosted [SatSale](https://github.com/nickfarrow/SatSale) instance) or by using [tippin.me](https://tippin.me/@kristapsk).
