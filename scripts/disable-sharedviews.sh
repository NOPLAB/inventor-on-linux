#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SharedViews loads .NET 10 references through Wine Mono and aborts Inventor.
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
prefix=$INVENTOR_PREFIX
bin="$prefix/drive_c/Program Files/Autodesk/Inventor 2027/Bin"
source_file="$bin/Addins/Autodesk.SharedViews.Inventor.addin"
if test -f "$source_file"; then
  mkdir -p "$bin/Addins-disabled"
  test ! -e "$bin/Addins-disabled/Autodesk.SharedViews.Inventor.addin"
  mv "$source_file" "$bin/Addins-disabled/"
fi
# InteractiveTutorial triggers the same unsupported Mono attribute lookup.
for relative in Addins/Autodesk.InteractiveTutorial.Inventor.addin InteractiveTutorial.dll en-US/InteractiveTutorial.resources.dll ja-JP/InteractiveTutorial.resources.dll; do
  if test -f "$bin/$relative"; then
    mkdir -p "$(dirname "$bin/Addins-disabled/$relative")"
    test ! -e "$bin/Addins-disabled/$relative"
    mv "$bin/$relative" "$bin/Addins-disabled/$relative"
  fi
done
