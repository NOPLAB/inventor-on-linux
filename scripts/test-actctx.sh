#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
base=$(cat result/share/inventor-unsafe/base-wine)
"$base/bin/winegcc" -m64 -o build/actctx-threading.exe tests/actctx-threading.c
export WINEPREFIX="$PWD/test-prefix" WINEDEBUG=-all
for candidate in "/run/user/$UID"/xauth_*; do
  if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
done
./result/bin/wine "$PWD/build/actctx-threading.exe.so"
