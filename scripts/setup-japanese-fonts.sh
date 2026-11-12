#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
export WINEPREFIX="$INVENTOR_PREFIX" WINEDEBUG=-all
for candidate in "/run/user/$UID"/xauth_*; do
  if test -f "$candidate"; then export XAUTHORITY="$candidate"; break; fi
done
wine="$INVENTOR_RUNNER/bin/wine"
font_dir=${INVENTOR_FONTS:-}
if test -z "$font_dir"; then font_dir=$(nix build "$project_dir#fonts" --no-link --print-out-paths); fi
cp "$font_dir/share/fonts/truetype/ipaexg.ttf" "$font_dir/share/fonts/truetype/ipaexm.ttf" "$WINEPREFIX/drive_c/windows/Fonts/"
mkdir -p "$state_dir/logs"
key='HKLM\Software\Microsoft\Windows NT\CurrentVersion'
test -e "$state_dir/logs/font-substitutes-before.reg" || "$wine" reg export "$key\FontSubstitutes" "Z:$state_dir/logs/font-substitutes-before.reg" /y >/dev/null
test -e "$state_dir/logs/font-link-before.reg" || "$wine" reg export "$key\FontLink" "Z:$state_dir/logs/font-link-before.reg" /y >/dev/null
"$wine" reg add "$key\Fonts" /v 'IPAexGothic (TrueType)' /t REG_SZ /d ipaexg.ttf /f
"$wine" reg add "$key\Fonts" /v 'IPAexMincho (TrueType)' /t REG_SZ /d ipaexm.ttf /f
for name in 'MS UI Gothic' 'MS Gothic' 'MS PGothic' Meiryo 'Meiryo UI' 'Yu Gothic' 'Yu Gothic UI'; do
  "$wine" reg add "$key\FontSubstitutes" /v "$name" /t REG_SZ /d IPAexGothic /f
done
for name in Tahoma 'Segoe UI' Arial 'Microsoft Sans Serif'; do
  "$wine" reg add "$key\FontLink\SystemLink" /v "$name" /t REG_MULTI_SZ /d 'ipaexg.ttf,IPAexGothic\0SEGUISYM.TTF,Segoe UI Symbol' /f
done
echo 'Japanese fallback configured. Restart Inventor after saving work to refresh its font cache.'
