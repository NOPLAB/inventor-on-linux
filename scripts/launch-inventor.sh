#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
export WINEPREFIX="$INVENTOR_PREFIX"
export INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}msquic=;dxgi,d3d11,d3d12,d3d12core=n,b"
if test -z "${XAUTHORITY:-}"; then
  for candidate in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/xauth_*; do
    if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
  done
fi
wine="$INVENTOR_RUNNER/bin/wine"
mkdir -p "$state_dir/logs"
# Inventor may not create this profile setting under Wine (startup error 82).
realdwg_settings="$WINEPREFIX/drive_c/users/${INVENTOR_WINE_USER:-$USER}/AppData/Roaming/Autodesk/Inventor 2027/RealDWGSettings.xml"
if ! test -e "$realdwg_settings" && test -d "$WINEPREFIX/drive_c/Program Files/Common Files/Autodesk Shared/RealDWG Shared 2027"; then
  mkdir -p "$(dirname "$realdwg_settings")"
  { printf '\xff\xfe'; printf '%s\r\n' '<?xml version="1.0" encoding="utf-16" standalone="no" ?>' '<RealDWGSettings InstallDirectory="C:\Program Files\Common Files\Autodesk Shared\RealDWG Shared 2027"></RealDWGSettings>' | iconv -f UTF-8 -t UTF-16LE; } > "$realdwg_settings"
fi
identity=$(identity_exe)
test -n "$identity" || { echo 'Identity Manager not installed.' >&2; exit 1; }
"$wine" "$identity" > "$state_dir/logs/identity-runtime.log" 2>&1 &
licensing=$(find "$WINEPREFIX/drive_c/Program Files (x86)/Common Files/Autodesk Shared/AdskLicensing" -path '*/AdskLicensingService/AdskLicensingService.exe' -type f | sort -V | tail -1)
test -n "$licensing" || { echo 'Autodesk Licensing Service not installed.' >&2; exit 1; }
"$wine" "$licensing" > "$state_dir/logs/licensing-runtime.log" 2>&1 &
sleep 5
cd "$WINEPREFIX/drive_c/Program Files/Autodesk/Inventor 2027/Bin"
exec "$wine" 'C:\Program Files\Autodesk\Inventor 2027\Bin\Inventor.exe' "$@"
