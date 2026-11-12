#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
runner=/opt/inventor-on-linux/runner
if test "${1:-}" = --version || test "${1:-}" = --help; then
  exec "$runner/runtime/bin/wine" "$@"
fi
: "${WINEPREFIX:?Set WINEPREFIX to a dedicated initialized Inventor prefix}"
test -d "$WINEPREFIX/drive_c/windows/system32" || {
  echo 'Initialize the dedicated prefix with inventor-on-linux init-prefix.' >&2
  exit 2
}
for pair in x86_64-windows:system32 i386-windows:syswow64; do
  arch=${pair%%:*}
  directory="$WINEPREFIX/drive_c/windows/${pair#*:}"
  test -d "$directory" || continue
  target="$directory/wintrust.dll"
  if ! test -e "$target.inventor-unsafe-original"; then
    if test -e "$target"; then
      cp -L "$target" "$target.inventor-unsafe-original"
    else
      cp -L "/opt/inventor-on-linux/base/lib/wine/$arch/wintrust.dll" "$target.inventor-unsafe-original"
    fi
  fi
  if ! cmp -s "$runner/lib/wine/$arch/wintrust.dll" "$target"; then
    cp --remove-destination "$runner/lib/wine/$arch/wintrust.dll" "$target"
  fi
done
if test -n "${DISPLAY:-}" && test "${INVENTOR_WINDOW_SHAPE_FIX:-1}" != 0; then
  setsid -f "$runner/bin/inventor-window-shape" >> "$WINEPREFIX/.inventor-window-shape.log" 2>&1
fi
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}wintrust=n"
exec "$runner/runtime/bin/wine" "$@"
