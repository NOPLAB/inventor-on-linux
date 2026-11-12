#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
project=$(cd -- "$(dirname -- "$0")/../.." && pwd)
mkdir -p "$project/build/debian" "$project/build/debian-downloads"
docker build -t inventor-on-linux-deb-builder "$project/packaging/debian"
docker run --rm --init \
  -e BUILD_JOBS="${BUILD_JOBS:-8}" \
  -v "$project:/src:ro" \
  -v "$project/build/debian:/work" \
  -v "$project/build/debian-downloads:/downloads" \
  inventor-on-linux-deb-builder
