#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
command=${1:-launch}
if test "$#" -gt 0; then shift; fi
case "$command" in
  --help|-h|help)
    cat <<HELP
Usage: inventor-on-linux [COMMAND] [ARGUMENTS...]

Commands:
  init-prefix        Create a new dedicated 64-bit Wine prefix with Windows 10 and DXVK
  setup-dxvk         Install DXVK into an initialized prefix (close its apps first)
  launch             Start Identity Manager, licensing service and Inventor (default)
  prepare-media DIR  Copy extracted official media and fetch verified payloads
  install            Install prepared media; accepts --dry-run
  register-runner    Copy the custom runner into Bottles
  setup-browser      Register the native browser and authentication callback
  setup-fonts        Configure IPAex Japanese fonts in the dedicated prefix
  disable-addins     Disable SharedViews and InteractiveTutorial
  repair-vc-runtime  Restore official VC++ DLLs from the installed package cache
  repair-licensing   Repair a diagnosed 1053 / LIC-INST-ERROR-69009748 install timeout
  restore-prefix DIR Stop that prefix and restore its original wintrust DLLs
  paths              Show effective prefix, state and runner paths
  --version          Print version

Configuration: $config_file
Use a dedicated Wine prefix; Bottles is optional. Autodesk software is not included.
HELP
    ;;
  --version) echo 'inventor-on-linux 0.1.0';;
  paths) printf 'prefix=%s\nstate=%s\nrunner=%s\n' "$WINEPREFIX" "$state_dir" "$INVENTOR_RUNNER";;
  launch) exec "$project_dir/scripts/launch-inventor.sh" "$@";;
  init-prefix) exec "$project_dir/scripts/init-prefix.sh" "$@";;
  setup-dxvk) exec "$project_dir/scripts/setup-dxvk.sh" "$@";;
  prepare-media) exec "$project_dir/scripts/prepare-media.sh" "$@";;
  install) exec "$project_dir/scripts/install-cached-media.sh" "$@";;
  register-runner) exec "$project_dir/scripts/register-bottles-runner.sh" "$@";;
  setup-browser) exec "$project_dir/scripts/setup-browser-integration.sh" "$@";;
  setup-fonts) exec "$project_dir/scripts/setup-japanese-fonts.sh" "$@";;
  disable-addins) exec "$project_dir/scripts/disable-sharedviews.sh" "$@";;
  repair-vc-runtime) exec "$project_dir/scripts/repair-vc-runtime.sh" "$@";;
  restore-prefix) exec "$project_dir/scripts/restore-prefix.sh" "$@";;
  repair-licensing)
    tools=$(media_tools)
    export PATH="$INVENTOR_RUNNER/bin:$tools/bin:$PATH"
    exec "$tools/bin/python3" "$project_dir/scripts/repair-licensing-install.py" "$@";;
  *) echo "Unknown command: $command (use --help)" >&2; exit 2;;
esac
