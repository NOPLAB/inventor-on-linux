#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
if test "$#" -ne 3; then
  echo "Usage: $0 PREFIX WINDOWS_MSIX_DLL WINDOWS_ADIX_FILE" >&2
  exit 2
fi
project_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
base_wine=$(cat result/share/inventor-unsafe/base-wine)
mkdir -p build logs
"$base_wine/bin/winegcc" -m64 -o build/msix-probe.exe tests/msix-probe.c
export WINEPREFIX="$1"
export WINEDEBUG=-all
set +e
WINEDLLOVERRIDES=wintrust=b "$base_wine/bin/wine" "$project_dir/build/msix-probe.exe.so" "$2" "$3" > logs/baseline-msix.log 2>&1
baseline_status=$?
set -e
cat logs/baseline-msix.log
test "$baseline_status" -ne 0 || { echo 'Baseline unexpectedly passed; inspect the prefix and overrides.' >&2; exit 1; }
./result/bin/wine "$project_dir/build/msix-probe.exe.so" "$2" "$3" | tee logs/patched-msix.log
