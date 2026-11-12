#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
cd "$project_dir"
export WINEPREFIX="$INVENTOR_PREFIX"
export INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1
export WINEDEBUG=-all
export INV_LOGDIR="$state_dir/logs"
tools=$(media_tools)
export PATH="$INVENTOR_RUNNER/bin:$tools/bin:$PATH"
if test -z "${XAUTHORITY:-}"; then
  for candidate in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/xauth_*; do
    if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
  done
fi
exec "$tools/bin/python3" "$project_dir/vendor/inventor-linux/scripts/install-from-image.py" \
  "$state_dir/build/install-media" --prefix "$WINEPREFIX" --lang ja-JP --no-content --prepared-prefix "$@"
