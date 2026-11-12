#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
# Desktop Exec has its own quoting rules. Refuse ambiguous paths rather than
# interpolating shell syntax into a URI handler.
case "$project_dir" in *[\"\`\$\\%]*) echo 'Move the project to a path without quotes, backticks, $, backslashes or %.' >&2; exit 2 ;; esac
for command in xdg-mime update-desktop-database; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
test -f "$WINEPREFIX/user.reg" || { echo 'Initialize the dedicated Wine prefix first (init-prefix).' >&2; exit 1; }
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$applications"
cat > "$applications/inventor-on-linux-auth.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Inventor on Linux Identity Manager
Exec="$project_dir/scripts/adskidmgr-callback.sh" %u
MimeType=x-scheme-handler/adskidmgr;x-scheme-handler/adsk.idmgr;
NoDisplay=true
Terminal=false
DESKTOP
update-desktop-database "$applications"
xdg-mime default inventor-on-linux-auth.desktop x-scheme-handler/adskidmgr
xdg-mime default inventor-on-linux-auth.desktop x-scheme-handler/adsk.idmgr
"$wine" reg add 'HKCU\Software\Wine\WineBrowser' /v Browsers /t REG_SZ /d "$project_dir/scripts/open-browser.sh" /f
printf 'Browser integration registered. Keep this project at its current path.\n'
