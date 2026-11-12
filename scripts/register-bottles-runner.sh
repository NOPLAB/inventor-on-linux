#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
cd "$project_dir"
test -x "$INVENTOR_RUNNER/bin/wine" || { echo 'Run nix build .#runner first.' >&2; exit 1; }
runner_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bottles/runners/inventor-unsafe-11.8"
if test -e "$runner_dir"; then
  echo "Already exists: $runner_dir" >&2
  exit 1
fi
mkdir -p "$(dirname -- "$runner_dir")"
# Bottles renames winemenubuilder.exe. Its runner directories must be writable.
cp -a "$(readlink -f "$INVENTOR_RUNNER")" "$runner_dir"
find "$runner_dir" -type d -exec chmod u+w {} +
echo "$runner_dir"
echo 'Select inventor-unsafe-11.8 only in the dedicated Inventor bottle.'
