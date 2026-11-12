#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
source "$(dirname -- "$0")/common.sh"
prefix=$INVENTOR_PREFIX
seven=$(media_tools)/bin/7zz
cache="$prefix/drive_c/ProgramData/Package Cache"
backup="$state_dir/build/vc-runtime-before-mesh-repair"
for spec in 'amd64:system32:{61B44572-8722-4DAF-8ACF-8E742D30BCC5}' 'x86:syswow64:{5A0DFA55-3851-45BC-8B20-95EA4BF5812D}'; do
 arch=${spec%%:*}; rest=${spec#*:}; directory=${rest%%:*}; guid=${rest#*:}
 cab="$cache/${guid}v14.50.35719/packages/vcRuntimeMinimum_$arch/cab1.cab"
 test -f "$cab"
 stage="$state_dir/build/vc-runtime-$arch"
 mkdir -p "$stage" "$backup/$directory"
 "$seven" x -y "-o$stage" "$cab" >/dev/null
 for file in "$stage"/*.dll_"$arch"; do
   name=$(basename "$file" "_$arch")
   target="$prefix/drive_c/windows/$directory/$name"
   if test -e "$target" && ! test -e "$backup/$directory/$name"; then cp -L "$target" "$backup/$directory/$name"; fi
   cp --remove-destination "$file" "$target"
   echo "Installed official $arch $name"
 done
done
