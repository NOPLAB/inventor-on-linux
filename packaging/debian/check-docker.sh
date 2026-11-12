#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
project=$(cd -- "$(dirname -- "$0")/../.." && pwd)
# Reuse the project's existing regression test for both PE architectures.
docker run --rm --init \
  -v "$project:/src:ro" -v "$project/build/debian:/work" \
  --entrypoint bash inventor-on-linux-deb-builder -c '
    set -e
    for pair in x86_64:64 i686:32; do
      "${pair%%:*}-w64-mingw32-gcc" -O2 /src/tests/msxml-attribute.c \
        -lole32 -loleaut32 -luuid -o "/work/msxml-attribute${pair#*:}.exe"
    done'
docker run --rm --init \
  -v "$project/build/debian:/packages:ro" \
  "${TEST_IMAGE:-ubuntu:24.04}" bash -c '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends /packages/inventor-on-linux_0.1.0_amd64.deb xvfb xauth
    if command -v nix; then
      echo "Use a clean image without Nix for this check." >&2
      exit 1
    fi
    inventor-on-linux --help
    inventor-on-linux prepare-media --help
    export INVENTOR_PREFIX=/tmp/inventor-test-prefix
    export INVENTOR_WINDOW_SHAPE_FIX=0 WINEDEBUG=-all
    xvfb-run -a bash -c '\''
      set -euo pipefail
      inventor-on-linux init-prefix
      runner=/opt/inventor-on-linux/runner
      dxvk=/opt/inventor-on-linux/dxvk
      for pair in x64:system32 x32:syswow64; do
        for dll in dxgi d3d11; do
          cmp "$dxvk/${pair%%:*}/$dll.dll" "$INVENTOR_PREFIX/drive_c/windows/${pair#*:}/$dll.dll"
        done
      done
      export WINEPREFIX="$INVENTOR_PREFIX"
      export INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1
      "$runner/bin/wine" /packages/msxml-attribute64.exe
      "$runner/bin/wine" /packages/msxml-attribute32.exe
      "$runner/bin/wine" reg query "HKCU\\Software\\Wine" /v Version
      /opt/inventor-on-linux/base/bin/wineserver -k
    '\''
  '
