#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
mkdir -p build
base=$(cat result/share/inventor-unsafe/base-wine)
"$base/bin/winegcc" -m64 -o build/inventor-typelib.exe tests/inventor-typelib.c -loleaut32 -luuid
export WINEPREFIX="${INVENTOR_PREFIX:-$PWD/test-prefix}" WINEDEBUG=-all
for candidate in "/run/user/$UID"/xauth_*; do
  if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
done
./result/bin/wine "$PWD/build/inventor-typelib.exe.so"
