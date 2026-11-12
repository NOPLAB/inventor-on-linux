#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
stage=${1:?Pass the package staging directory}
root="$stage/opt/inventor-on-linux"
find "$root/base" "$root/runner" -type f \( -name '*.dll' -o -name '*.exe' \) -print0 |
  xargs -0 -r -P4 -n32 x86_64-w64-mingw32-strip --strip-debug
find "$root/base" "$root/runner" -type f -name '*.so' -print0 |
  xargs -0 -r -P4 -n32 strip --strip-debug
# Preserve the native wintrust override marker through PE rewriting.
python3 - "$root" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
for arch in ('x86_64-windows', 'i386-windows'):
    for tree in ('runner/lib/wine', 'runner/runtime/lib/wine'):
        path = root / tree / arch / 'wintrust.dll'
        data = path.read_bytes()
        assert data[:2] == b'MZ'
        path.write_bytes(data[:64] + b'Inventor unsafe!' + data[80:])
PY
