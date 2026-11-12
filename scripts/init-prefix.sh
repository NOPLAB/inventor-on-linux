#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
if test "$#" -ne 0; then echo 'Usage: inventor-on-linux init-prefix' >&2; exit 2; fi
if test -L "$WINEPREFIX" || { test -e "$WINEPREFIX" && { ! test -d "$WINEPREFIX" || test -n "$(find "$WINEPREFIX" -mindepth 1 -maxdepth 1 -print -quit)"; }; }; then
  echo "Refusing to initialize a nonempty prefix: $WINEPREFIX" >&2
  echo 'Choose a new dedicated prefix, or use setup-dxvk for an existing one.' >&2
  exit 1
fi
# The patched wrapper requires an initialized prefix. Bootstrap with the exact
# stock Wine version recorded by the runner, then use the patched Wine normally.
base_wine=$(cat "$INVENTOR_RUNNER/share/inventor-unsafe/base-wine")
test -x "$base_wine/bin/wineboot"
dxvk=$(dxvk_tools)
test -f "$dxvk/x64/d3d11.dll"
test -f "$dxvk/x32/d3d11.dll"
mkdir -p "$WINEPREFIX"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"
WINEDLLOVERRIDES='mscoree,mshtml=' "$base_wine/bin/wineboot" -i
"$base_wine/bin/wineserver" -w
"$base_wine/bin/wine" reg add 'HKCU\Software\Wine' /v Version /t REG_SZ /d win10 /f
"$base_wine/bin/wineserver" -w
export INVENTOR_DXVK="$dxvk"
"$project_dir/scripts/setup-dxvk.sh"
printf 'Initialized dedicated Wine prefix: %s\n' "$WINEPREFIX"
