#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
test -x result/bin/wine || { echo 'Run nix build .#runner first.' >&2; exit 1; }
base_wine=$(cat result/share/inventor-unsafe/base-wine)
mkdir -p build logs
"$base_wine/bin/winegcc" -m64 -o build/wintrust-api.exe tests/wintrust-api.c
export WINEPREFIX="$project_dir/test-prefix"
export WINEDLLOVERRIDES='mscoree,mshtml=d;wintrust=b'
export WINEDEBUG=-all
# A freshly created prefix may not yet have registered its trust providers.
"$base_wine/bin/wine" regsvr32 /s wintrust.dll > logs/register-trust.log 2>&1
"$base_wine/bin/wine" "$project_dir/build/wintrust-api.exe.so" | tee logs/baseline-api.log
./result/bin/wine "$project_dir/build/wintrust-api.exe.so" --expect-success | tee logs/patched-api.log
INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1 ./result/bin/wine "$project_dir/build/wintrust-api.exe.so" | tee logs/file-errors-api.log
