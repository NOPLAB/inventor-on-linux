#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
jobs=${BUILD_JOBS:-8}
version=0.1.0
prefix=/opt/inventor-on-linux
stage=/work/package
fetch() {
  local name=$1 url=$2 digest=$3
  if ! test -f "/downloads/$name" || ! echo "$digest  /downloads/$name" | sha256sum -c - >/dev/null 2>&1; then
    curl -fL --retry 3 "$url" -o "/downloads/$name.partial"
    echo "$digest  /downloads/$name.partial" | sha256sum -c -
    mv "/downloads/$name.partial" "/downloads/$name"
  fi
}
fetch wine-11.8.tar.xz https://dl.winehq.org/wine/source/11.x/wine-11.8.tar.xz 53aa85995d4b97f0116a1c56b8a6a1417730ef59a277819d2d3d31364ea556b0
fetch wine-staging-11.8.tar.gz https://codeload.github.com/wine-staging/wine-staging/tar.gz/refs/tags/v11.8 843a2670067befab0d27cfd268251f0e40047f55b78f326ce9ae5c717e0eeb05
# Recreate the source on every build so changes to project patches are applied.
rm -rf /work/source
mkdir /work/source
tar -xf /downloads/wine-11.8.tar.xz -C /work/source --strip-components=1
mkdir -p /work/staging
tar -xf /downloads/wine-staging-11.8.tar.gz -C /work/staging --strip-components=1
python3 /work/staging/staging/patchinstall.py DESTDIR=/work/source --all
mkdir -p /work/wine-build
cd /work/wine-build
/work/source/configure --prefix="$prefix/base" --libdir="$prefix/base/lib" \
  --enable-archs=x86_64,i386 --without-wayland --disable-tests
make -j "$jobs"
rm -rf "$stage"
make install DESTDIR="$stage"
fetch wine-mono-11.0.0-x86.msi https://dl.winehq.org/wine/wine-mono/11.0.0/wine-mono-11.0.0-x86.msi d7efede0b9bdcf52134f8cd6ced59d9fece976f70b11a400bdb47b864569cd27
fetch wine-gecko-2.47.4-x86_64.msi https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi e590b7d988a32d6aa4cf1d8aa3aa3d33766fdd4cf4c89c2dcc2095ecb28d066f
mkdir -p "$stage$prefix/base/share/wine/mono" "$stage$prefix/base/share/wine/gecko"
cp /downloads/wine-mono-11.0.0-x86.msi "$stage$prefix/base/share/wine/mono/"
cp /downloads/wine-gecko-2.47.4-x86_64.msi "$stage$prefix/base/share/wine/gecko/"
# Build only the changed DLLs after preserving the matching stock runtime.
for patch_file in /src/patches/*.patch; do patch -d /work/source -p1 < "$patch_file"; done
make -j "$jobs" dlls/wintrust/all dlls/comctl32/all dlls/comctl32_v6/all \
  dlls/ntdll/all dlls/rpcrt4/all dlls/combase/all dlls/oleaut32/all dlls/msxml3/all dlls/msxml6/all
runner="$stage$prefix/runner"
mkdir -p "$runner/runtime" "$runner/lib/wine" "$runner/bin" "$runner/share/inventor-unsafe"
cp -a "$stage$prefix/base/." "$runner/runtime/"
for arch in x86_64-windows i386-windows; do
  mkdir -p "$runner/lib/wine/$arch"
  for dll in wintrust comctl32 comctl32_v6 ntdll rpcrt4 combase oleaut32 msxml3 msxml6; do
    cp --remove-destination "dlls/$dll/$arch/$dll.dll" "$runner/runtime/lib/wine/$arch/$dll.dll"
  done
  # Native override must not redirect the patched PE to a stock builtin.
  python3 - "$runner/runtime/lib/wine/$arch/wintrust.dll" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
data = path.read_bytes()
assert data[64:80] == b'Wine builtin DLL'
path.write_bytes(data[:64] + b'Inventor unsafe!' + data[80:])
PY
  cp "$runner/runtime/lib/wine/$arch/wintrust.dll" "$runner/lib/wine/$arch/"
  for assembly in "$runner/runtime/lib/wine/$arch/"*_microsoft.windows.common-controls_*; do
    test -d "$assembly" || continue
    cp --remove-destination "dlls/comctl32_v6/$arch/comctl32_v6.dll" "$assembly/comctl32.dll"
  done
done
# The installed loader finds the runtime relative to its actual location.
for entry in "$runner/runtime/bin/"*; do
  ln -s "$prefix/runner/runtime/bin/$(basename "$entry")" "$runner/bin/$(basename "$entry")"
done
rm "$runner/bin/wine"
install -m755 /src/packaging/debian/wine-wrapper.sh "$runner/bin/wine"
printf '%s\n' "$prefix/base" > "$runner/share/inventor-unsafe/base-wine"
gcc -O2 -Wall -Wextra /src/tools/inventor-window-shape.c -o "$runner/bin/inventor-window-shape" -lX11 -lXext

app="$stage/usr/share/inventor-on-linux"
mkdir -p "$app" "$stage/usr/bin" "$stage/usr/share/applications" "$stage/usr/share/doc/inventor-on-linux"
cp -a /src/scripts /src/vendor /src/patches /src/LICENSE /src/THIRD_PARTY_NOTICES.md "$app/"
find "$app/scripts" -name 'test-*' -delete
find "$app" -type d -name __pycache__ -prune -exec rm -rf {} +
cat > "$app/package-defaults.sh" <<'DEFAULTS'
export INVENTOR_RUNNER="${INVENTOR_RUNNER:-/opt/inventor-on-linux/runner}"
export INVENTOR_MEDIA_TOOLS="${INVENTOR_MEDIA_TOOLS:-/usr}"
export INVENTOR_FONTS="${INVENTOR_FONTS:-/opt/inventor-on-linux/fonts}"
export INVENTOR_DXVK="${INVENTOR_DXVK:-/opt/inventor-on-linux/dxvk}"
export INVENTOR_STATE_DIR="${INVENTOR_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/inventor-on-linux}"
DEFAULTS
cat > "$stage/usr/bin/inventor-on-linux" <<'LAUNCH'
#!/bin/bash
exec /usr/share/inventor-on-linux/scripts/inventor-on-linux.sh "$@"
LAUNCH
chmod 755 "$stage/usr/bin/inventor-on-linux"
mkdir -p "$stage$prefix/fonts/share/fonts/truetype"
find /usr/share/fonts -iname 'ipaex*.ttf' -exec cp {} "$stage$prefix/fonts/share/fonts/truetype/" \;
cat > "$stage/usr/share/applications/inventor-on-linux.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Inventor on Linux
Comment=Start Autodesk Inventor in a dedicated Wine prefix
Exec=inventor-on-linux launch
Icon=applications-engineering
Categories=Graphics;Engineering;
Terminal=false
DESKTOP
# DXVK comes from the same pinned 2.7.1 release used by the Nix package.
fetch dxvk-2.7.1.tar.gz https://github.com/doitsujin/dxvk/releases/download/v2.7.1/dxvk-2.7.1.tar.gz d85ce7c79f57ecd765aaa1b9e7007cb875e6fde9f6d331df799bce73d513ce87
mkdir -p "$stage$prefix/dxvk"
tar -xf /downloads/dxvk-2.7.1.tar.gz -C "$stage$prefix/dxvk" --strip-components=1
cp /src/README.md /src/VALIDATION.md /src/THIRD_PARTY_NOTICES.md "$stage/usr/share/doc/inventor-on-linux/"
cp /src/LICENSE "$stage/usr/share/doc/inventor-on-linux/copyright"
cp /src/patches/COPYING.LIB "$stage/usr/share/doc/inventor-on-linux/Wine-LGPL-2.1"
cp /usr/share/doc/fonts-ipaexfont-gothic/copyright "$stage/usr/share/doc/inventor-on-linux/IPAex-copyright"
/src/packaging/debian/strip-runtime.sh "$stage"
# Keep exact Wine and staging sources alongside the binary for redistribution.
XZ_OPT="-T$jobs -3" tar -cJf "/work/inventor-on-linux_${version}_wine-source.tar.xz" -C /work source staging -C /src patches packaging
mkdir -p "$stage/DEBIAN"
cat > "$stage/DEBIAN/control" <<CONTROL
Package: inventor-on-linux
Version: $version
Architecture: amd64
Maintainer: NOPLAB <noreply@github.com>
Section: graphics
Priority: optional
Installed-Size: $(du -sk "$stage" | cut -f1)
Homepage: https://github.com/NOPLAB/inventor-on-linux
Depends: bash, python3, 7zip, coreutils, findutils, grep, sed, util-linux, xdg-utils, desktop-file-utils, libc6 (>= 2.39), libfreetype6, libfontconfig1, libgnutls30t64, libunwind8, libx11-6, libxext6, libxrender1, libxrandr2, libxi6, libxcursor1, libxinerama1, libxxf86vm1, libvulkan1, libgl1, libasound2t64, libpulse0, libdbus-1-3, libudev1, libcups2t64, libsdl2-2.0-0, libusb-1.0-0, libgphoto2-6t64, libpcsclite1, libkrb5-3, libpcap0.8t64, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Recommends: mesa-vulkan-drivers
Description: Experimental Wine runner and tools for Autodesk Inventor 2027
 Includes patched Wine and DXVK. Obtain Autodesk software separately with a
 valid entitlement. BLOB signature verification is bypassed in dedicated prefixes.
CONTROL
find "$stage" -type d -exec chmod 755 {} +
dpkg-deb -Zxz -z3 --threads-max="$jobs" --root-owner-group --build "$stage" "/work/inventor-on-linux_${version}_amd64.deb"
