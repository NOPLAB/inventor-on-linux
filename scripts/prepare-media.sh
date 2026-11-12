#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
tools=$(media_tools)
exec "$tools/bin/python3" "$project_dir/scripts/prepare-media.py" "$@"
