# SPDX-License-Identifier: MIT
{ lib, stdenvNoCC, makeWrapper, bash, coreutils, findutils, gnugrep
, gnused, glibc, xdg-utils, desktop-file-utils, runner, mediaTools, fonts }:
stdenvNoCC.mkDerivation {
  pname = "inventor-on-linux";
  version = "0.1.0";
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      (lib.fileset.fileFilter (file: (file.hasExt "sh" || file.hasExt "py") && !lib.hasPrefix "test-" file.name) ../scripts)
      (lib.fileset.fileFilter (file: file.hasExt "py" || file.name == "LICENSE" || file.name == "UPSTREAM_COMMIT") ../vendor)
      ../LICENSE ../THIRD_PARTY_NOTICES.md ../patches
    ];
  };
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/inventor-on-linux" "$out/bin" "$out/share/applications"
    cp -r scripts vendor patches LICENSE THIRD_PARTY_NOTICES.md "$out/share/inventor-on-linux/"
    chmod -R u+w "$out/share/inventor-on-linux"
    cat > "$out/share/inventor-on-linux/package-defaults.sh" <<'DEFAULTS'
    export INVENTOR_RUNNER="''${INVENTOR_RUNNER:-${runner}}"
    export INVENTOR_MEDIA_TOOLS="''${INVENTOR_MEDIA_TOOLS:-${mediaTools}}"
    export INVENTOR_FONTS="''${INVENTOR_FONTS:-${fonts}}"
    export INVENTOR_STATE_DIR="''${INVENTOR_STATE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/inventor-on-linux}"
    export PATH="${lib.makeBinPath [ bash coreutils findutils gnugrep gnused glibc.bin xdg-utils desktop-file-utils ]}:$PATH"
    DEFAULTS
    patchShebangs "$out/share/inventor-on-linux/scripts"
    makeWrapper ${bash}/bin/bash "$out/bin/inventor-on-linux" \
      --add-flags "$out/share/inventor-on-linux/scripts/inventor-on-linux.sh" \
      --set-default INVENTOR_RUNNER ${runner} \
      --set-default INVENTOR_MEDIA_TOOLS ${mediaTools} \
      --set-default INVENTOR_FONTS ${fonts} \
      --run 'export INVENTOR_STATE_DIR="''${INVENTOR_STATE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/inventor-on-linux}"' \
      --prefix PATH : ${lib.makeBinPath [ bash coreutils findutils gnugrep gnused glibc.bin xdg-utils desktop-file-utils ]}
    cat > "$out/share/applications/inventor-on-linux.desktop" <<DESKTOP
    [Desktop Entry]
    Type=Application
    Name=Inventor on Linux
    Comment=Start Autodesk Inventor in a dedicated Wine prefix
    Exec=$out/bin/inventor-on-linux launch
    Icon=applications-engineering
    Categories=Graphics;Engineering;
    Terminal=false
    DESKTOP
    runHook postInstall
  '';
  meta = {
    description = "Experimental Wine runner and setup tools for Autodesk Inventor 2027";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "inventor-on-linux";
  };
}
