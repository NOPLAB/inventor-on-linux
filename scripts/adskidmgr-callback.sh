#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Forward the browser callback to the real Identity Manager without logging its code.
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
mkdir -p "$state_dir/logs"
test "$#" -eq 1 || exit 2
scheme=${1%%:*}
case "${scheme,,}" in adskidmgr|adsk.idmgr) ;; *)
  printf '%s callback rejected: unexpected scheme\n' "$(date -Is)" >> "$state_dir/logs/callback-status.log"
  exit 2 ;;
esac
printf '%s callback received\n' "$(date -Is)" >> "$state_dir/logs/callback-status.log"
export WINEPREFIX="$INVENTOR_PREFIX"
export INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1 WINEDEBUG=-all
if test -z "${XAUTHORITY:-}"; then
  for candidate in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/xauth_*; do
    if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
  done
fi
shopt -s nullglob
for event in "$WINEPREFIX/drive_c/ProgramData/Autodesk/IDSDK"/*/interprocess/*/IDSDKQuit-v2-*; do
  pid=${event##*IDSDKQuit-v2-}
  [[ $pid =~ ^[0-9]+$ ]] || continue
  target="$(dirname -- "$event")/AdOAuth2Code-$pid"
  if ! test -e "$target"; then
    { printf '\001'; head -c 23 /dev/zero; } > "$target"
  fi
done
status=0
identity=$(identity_exe)
test -n "$identity" || exit 1
"$wine" "$identity" "$1" >/dev/null 2>&1 || status=$?
printf '%s Identity Manager client exit=%d\n' "$(date -Is)" "$status" >> "$state_dir/logs/callback-status.log"
exit "$status"
