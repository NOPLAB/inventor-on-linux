#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Source from a script, after enabling set -euo pipefail.
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config_file="${INVENTOR_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/inventor-on-linux/config.sh}"
if test -f "$config_file"; then source "$config_file"; fi
if test -f "$project_dir/config.local.sh"; then source "$project_dir/config.local.sh"; fi
if test -f "$project_dir/package-defaults.sh"; then source "$project_dir/package-defaults.sh"; fi
export INVENTOR_STATE_DIR="${INVENTOR_STATE_DIR:-$project_dir}"
state_dir="$INVENTOR_STATE_DIR"
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/bottles/bottles/Inventor2027}"
export WINEPREFIX="$INVENTOR_PREFIX"
export INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1
export INVENTOR_RUNNER="${INVENTOR_RUNNER:-$project_dir/result}"
wine="$INVENTOR_RUNNER/bin/wine"
if test -z "${XAUTHORITY:-}"; then
  for candidate in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/xauth_*; do
    if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
  done
fi
identity_exe() {
  local root="$WINEPREFIX/drive_c/Program Files/Autodesk/AdskIdentityManager"
  if test -f "$root/Current/AdskIdentityManager.exe"; then
    printf '%s\n' "$root/Current/AdskIdentityManager.exe"
  else
    find "$root" -mindepth 2 -maxdepth 2 -name AdskIdentityManager.exe -type f | sort -V | tail -1
  fi
}
media_tools() {
  if test -n "${INVENTOR_MEDIA_TOOLS:-}"; then printf '%s\n' "$INVENTOR_MEDIA_TOOLS";
  else nix build "$project_dir#media-tools" --no-link --print-out-paths; fi
}
