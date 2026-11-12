#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
if test "$#" -ne 1; then echo "Usage: $0 PREFIX" >&2; exit 2; fi
source "$(dirname -- "$0")/common.sh"
base_wine=$(cat "$INVENTOR_RUNNER/share/inventor-unsafe/base-wine")
export WINEPREFIX="$1"
# wineserver -k returns 1 when this prefix has no running server.
if "$base_wine/bin/wineserver" -k; then :; else
  status=$?
  test "$status" -eq 1 || exit "$status"
fi
for directory in system32 syswow64; do
  target="$WINEPREFIX/drive_c/windows/$directory/wintrust.dll"
  if test -e "$target.inventor-unsafe-original"; then
    cp --remove-destination "$target.inventor-unsafe-original" "$target"
    rm "$target.inventor-unsafe-original"
    echo "Restored: $target"
  fi
done
