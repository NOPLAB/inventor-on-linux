#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
if test "$#" -ne 0; then echo 'Usage: inventor-on-linux setup-dxvk' >&2; exit 2; fi
test -f "$WINEPREFIX/user.reg" || { echo 'Initialize the dedicated Wine prefix first (init-prefix).' >&2; exit 1; }
test -d "$WINEPREFIX/drive_c/windows/syswow64" || { echo 'A 64-bit Wine prefix is required.' >&2; exit 1; }
dxvk=$(dxvk_tools)
# Wine's new WoW64 loader runs winepath as a 64-bit program. Avoid relying on
# wine vs wine64 to infer architecture: system32 is x64, syswow64 is x86.
for arch in x64 x32; do
  for dll in d3d11 dxgi; do test -f "$dxvk/$arch/$dll.dll"; done
done
for pair in x64:system32 x32:syswow64; do
  arch=${pair%%:*}
  directory="$WINEPREFIX/drive_c/windows/${pair#*:}"
  for dll in d3d11 dxgi; do
    target="$directory/$dll.dll"
    if test -e "$target" && ! test -e "$target.inventor-dxvk-original"; then
      cp -L "$target" "$target.inventor-dxvk-original"
    fi
    cp --remove-destination "$dxvk/$arch/$dll.dll" "$target"
  done
done
for dll in d3d11 dxgi; do
  "$wine" reg add 'HKCU\Software\Wine\DllOverrides' /v "$dll" /t REG_SZ /d native,builtin /f
done
printf 'Installed DXVK for Direct3D 11 in: %s\n' "$WINEPREFIX"
