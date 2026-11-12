# Licenses and third-party components

Original scripts, tests, tools, build configuration and documentation are MIT
licensed; see [LICENSE](LICENSE). This grant does not relicense third-party code.

| Component | License | Source / notice |
| --- | --- | --- |
| `patches/*.patch`, including locally authored Wine changes | LGPL-2.1-or-later, as modifications of Wine | [COPYING.LIB](patches/COPYING.LIB), [patch provenance](patches/UPSTREAM.md) |
| `vendor/inventor-linux/` | MIT, retaining original copyright notices | [LICENSE](vendor/inventor-linux/LICENSE), [pinned commit](vendor/inventor-linux/UPSTREAM_COMMIT) |
| Wine and Wine Staging runtime fetched by Nix | LGPL-2.1-or-later and notices shipped with their sources | Nixpkgs source pin in `flake.lock`; Wine derivation in `flake.nix` |
| Other Nix dependencies, including IPAex fonts | Respective upstream licenses | Fetched by Nix; not relicensed or vendored here |

The patches do not make the Wine runtime MIT licensed. If distributing compiled
Wine binaries, retain Wine's notices and comply with its LGPL source-distribution
requirements. This repository contains the patches and build recipes; it does not
ship a binary Wine release.

Autodesk installers, DLLs, fonts from Windows, models, login tokens and license
files are not distributed by this project. Obtain proprietary components directly
from their providers under their own terms. A valid Autodesk account and entitlement
are required. This project does not modify license validation.

Autodesk and Inventor are trademarks of their respective owners. This is an
independent experiment, not an Autodesk product or an endorsed compatibility layer.
