{
  description = "Experimental Autodesk Inventor 2027 compatibility runner";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c56a87d8e41ce69bd2af57eb35dcc117a9dfca33";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      base = pkgs.wineWow64Packages.staging;
      trustDlls = base.overrideAttrs (old: {
        pname = "inventor-unsafe-wintrust";
        patches = (old.patches or []) ++ [ ./patches/wintrust-bypass-verification.patch
          ./patches/comctl32-statusbar-erase-background.patch
          ./patches/ntdll-actctx-threadingmodel-case.patch
          ./patches/rpcrt4-ndrstubcall3.patch
          ./patches/combase-stub-activation-context.patch ];
        buildPhase = ''
          runHook preBuild
          make -j "$NIX_BUILD_CORES" dlls/wintrust/all dlls/comctl32/all dlls/comctl32_v6/all dlls/ntdll/all dlls/rpcrt4/all dlls/combase/all
          runHook postBuild
        '';
        installPhase = ''
          mkdir -p "$out/lib/wine"
          for arch in x86_64-windows i386-windows; do
            mkdir -p "$out/lib/wine/$arch"
            for dll in wintrust comctl32 comctl32_v6 ntdll rpcrt4 combase; do
              cp "dlls/$dll/$arch/$dll.dll" "$out/lib/wine/$arch/$dll.dll"
            done
            # Native override must not redirect this PE to Wine's stock builtin.
            python3 - "$out/lib/wine/$arch/wintrust.dll" <<'PY'
          from pathlib import Path
          import sys
          p = Path(sys.argv[1])
          data = p.read_bytes()
          assert data[64:80] == b'Wine builtin DLL'
          p.write_bytes(data[:64] + b'Inventor unsafe!' + data[80:])
          PY
          done
        '';
        postInstall = "";
        postFixup = "";
      });
      automationDlls = base.overrideAttrs (old: {
        pname = "inventor-oleaut32";
        patches = (old.patches or []) ++ [
          ./patches/oleaut32-typedesc-pointee.patch
          ./patches/oleaut32-typedesc-z-offsets.patch
        ];
        buildPhase = ''
          runHook preBuild
          make -j "$NIX_BUILD_CORES" dlls/oleaut32/all
          runHook postBuild
        '';
        installPhase = ''
          for arch in x86_64-windows i386-windows; do
            mkdir -p "$out/lib/wine/$arch"
            cp "dlls/oleaut32/$arch/oleaut32.dll" "$out/lib/wine/$arch/"
          done
        '';
        postInstall = "";
        postFixup = "";
      });
      xmlDlls = base.overrideAttrs (old: {
        pname = "inventor-msxml";
        patches = (old.patches or []) ++ [ ./patches/msxml3-nodemap-return-inserted.patch ];
        buildPhase = ''
          runHook preBuild
          make -j "$NIX_BUILD_CORES" dlls/msxml3/all dlls/msxml6/all
          runHook postBuild
        '';
        installPhase = ''
          for arch in x86_64-windows i386-windows; do
            mkdir -p "$out/lib/wine/$arch"
            for dll in msxml3 msxml6; do
              cp "dlls/$dll/$arch/$dll.dll" "$out/lib/wine/$arch/"
            done
          done
        '';
        postInstall = "";
        postFixup = "";
      });
      shapeFix = pkgs.stdenv.mkDerivation {
        pname = "inventor-window-shape";
        version = "1";
        src = ./tools/inventor-window-shape.c;
        dontUnpack = true;
        buildInputs = [ pkgs.libx11 pkgs.libxext ];
        buildPhase = ''
          $CC -O2 -Wall -Wextra "$src" -o inventor-window-shape -lX11 -lXext
        '';
        installPhase = ''
          install -Dm755 inventor-window-shape "$out/bin/inventor-window-shape"
        '';
      };
      runner = pkgs.runCommand "wine-inventor-unsafe-${base.version}" { } ''
        mkdir -p "$out/bin" "$out/lib/wine"
        ln -s ${shapeFix}/bin/inventor-window-shape "$out/bin/inventor-window-shape"
        for entry in ${base}/bin/*; do
          ln -s "$entry" "$out/bin/$(basename "$entry")"
        done
        for entry in ${base}/lib/wine/*; do
          arch=$(basename "$entry")
          if test -d "${trustDlls}/lib/wine/$arch"; then
            mkdir -p "$out/lib/wine/$arch"
            for dll in "$entry"/*; do
              ln -s "$dll" "$out/lib/wine/$arch/$(basename "$dll")"
            done
            ln -sfn "${trustDlls}/lib/wine/$arch/wintrust.dll" "$out/lib/wine/$arch/wintrust.dll"
          else
            ln -s "$entry" "$out/lib/wine/$arch"
          fi
        done
        mkdir -p "$out/share"
        for entry in ${base}/share/*; do
          ln -s "$entry" "$out/share/$(basename "$entry")"
        done
        ln -s ${base}/include "$out/include"
        rm "$out/bin/wine"
        cat > "$out/bin/wine" <<EOF
        #!${pkgs.runtimeShell}
        if test "\''${1:-}" = --version || test "\''${1:-}" = --help; then
          exec $out/runtime/bin/wine "\$@"
        fi
        : "\''${WINEPREFIX:?Set WINEPREFIX to a dedicated initialized Inventor prefix}"
        if ! test -d "\$WINEPREFIX/drive_c/windows/system32"; then
          echo 'Initialize the dedicated prefix with stock Wine before using this runner.' >&2
          exit 2
        fi
        for pair in x86_64-windows:system32 i386-windows:syswow64; do
          arch=\''${pair%%:*}
          directory=\$WINEPREFIX/drive_c/windows/\''${pair#*:}
          test -d "\$directory" || continue
          target=\$directory/wintrust.dll
          if ! test -e "\$target.inventor-unsafe-original"; then
            if test -e "\$target"; then
              ${pkgs.coreutils}/bin/cp -L "\$target" "\$target.inventor-unsafe-original"
            else
              ${pkgs.coreutils}/bin/cp -L "${base}/lib/wine/\$arch/wintrust.dll" "\$target.inventor-unsafe-original"
            fi
          fi
          if ! ${pkgs.diffutils}/bin/cmp -s "$out/lib/wine/\$arch/wintrust.dll" "\$target"; then
            ${pkgs.coreutils}/bin/cp --remove-destination "$out/lib/wine/\$arch/wintrust.dll" "\$target"
          fi
        done
        if test -n "\''${DISPLAY:-}" && test "\''${INVENTOR_WINDOW_SHAPE_FIX:-1}" != 0; then
          ${pkgs.util-linux}/bin/setsid -f "$out/bin/inventor-window-shape" >> "\$WINEPREFIX/.inventor-window-shape.log" 2>&1
        fi
        export WINEDLLOVERRIDES="\''${WINEDLLOVERRIDES:+\$WINEDLLOVERRIDES;}wintrust=n"
        exec $out/runtime/bin/wine "\$@"
        EOF
        chmod +x "$out/bin/wine"
        mkdir -p "$out/runtime/bin" "$out/runtime/lib/wine"
        cp ${base}/bin/wine "$out/runtime/bin/wine"
        ln -s ${base}/bin/wineserver "$out/runtime/bin/wineserver"
        ln -s ${base}/share "$out/runtime/share"
        for arch in x86_64-windows i386-windows x86_64-unix; do
          mkdir -p "$out/runtime/lib/wine/$arch"
          for entry in ${base}/lib/wine/$arch/*; do
            ln -s "$entry" "$out/runtime/lib/wine/$arch/$(basename "$entry")"
          done
        done
        for entry in ntdll.so wine wine-preloader; do
          rm "$out/runtime/lib/wine/x86_64-unix/$entry"
          cp ${base}/lib/wine/x86_64-unix/$entry "$out/runtime/lib/wine/x86_64-unix/$entry"
        done
        for arch in x86_64-windows i386-windows; do
          ln -sfn "${automationDlls}/lib/wine/$arch/oleaut32.dll" "$out/runtime/lib/wine/$arch/oleaut32.dll"
          for dll in msxml3 msxml6; do
            ln -sfn "${xmlDlls}/lib/wine/$arch/$dll.dll" "$out/runtime/lib/wine/$arch/$dll.dll"
          done
          for dll in ntdll rpcrt4 combase comctl32; do
            ln -sfn "${trustDlls}/lib/wine/$arch/$dll.dll" "$out/runtime/lib/wine/$arch/$dll.dll"
          done
          ln -sfn "${trustDlls}/lib/wine/$arch/comctl32_v6.dll" "$out/runtime/lib/wine/$arch/comctl32_v6.dll"
        done
        # Version 6 is located in Wine's side-by-side assembly directory.
        for arch in x86_64-windows i386-windows; do
          for assembly in ${base}/lib/wine/$arch/*_microsoft.windows.common-controls_*; do
            test -d "$assembly" || continue
            target="$out/runtime/lib/wine/$arch/$(basename "$assembly")"
            rm -f "$target"
            mkdir -p "$target"
            for entry in "$assembly"/*; do ln -s "$entry" "$target/$(basename "$entry")"; done
            ln -sfn "${trustDlls}/lib/wine/$arch/comctl32_v6.dll" "$target/comctl32.dll"
          done
        done
        mkdir -p "$out/share/inventor-unsafe"
        printf '%s\n' '${base}' > "$out/share/inventor-unsafe/base-wine"
        printf '%s\n' 'UNSAFE: BLOB trust verification is bypassed. Set INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1 to retain normal file errors. Dedicated prefix only; wintrust DLLs remain installed until restored.' > "$out/share/inventor-unsafe/NOTICE"
      '';
      mediaTools = pkgs.buildEnv {
        name = "inventor-media-tools";
        paths = [ pkgs.python3 pkgs._7zz ];
      };
      inventor = pkgs.callPackage ./nix/package.nix {
        inherit runner mediaTools;
        fonts = pkgs.ipaexfont;
        dxvk = pkgs.dxvk.bin;
      };
    in {
      packages.${system} = {
        default = inventor;
        inventor-on-linux = inventor;
        inherit runner;
        wintrust = trustDlls;
        fonts = pkgs.ipaexfont;
        dxvk = pkgs.dxvk.bin;
        media-tools = mediaTools;
        window-shape = shapeFix;
      };
      apps.${system} = {
        default = self.apps.${system}.inventor-on-linux;
        inventor-on-linux = {
          type = "app";
          program = "${inventor}/bin/inventor-on-linux";
          meta.description = "Run and configure Inventor in a dedicated Wine prefix";
        };
      };
      overlays.default = final: _prev: {
        inventor-on-linux = self.packages.${final.stdenv.hostPlatform.system}.inventor-on-linux;
      };
      checks.${system} = {
        script-syntax = pkgs.runCommand "inventor-script-syntax" {
          nativeBuildInputs = [ pkgs.bash pkgs.python3 ];
        } ''
          for script in ${self}/scripts/*.sh; do bash -n "$script"; done
          PYTHONPYCACHEPREFIX="$TMPDIR/pycache" python3 -m compileall -q ${self}/scripts ${self}/vendor
          touch "$out"
        '';
        package-smoke = pkgs.runCommand "inventor-package-smoke" { nativeBuildInputs = [ pkgs.desktop-file-utils ]; } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          desktop-file-validate ${inventor}/share/applications/inventor-on-linux.desktop
          ${inventor}/bin/inventor-on-linux --help > help.txt
          grep -q 'prepare-media' help.txt
          ${inventor}/bin/inventor-on-linux paths > paths.txt
          grep -F "state=$HOME/.local/state/inventor-on-linux" paths.txt
          grep -F "prefix=$HOME/.local/share/inventor-on-linux/prefix" paths.txt
          WINEPREFIX="$HOME/custom-prefix" ${inventor}/bin/inventor-on-linux paths > custom-paths.txt
          grep -F "prefix=$HOME/custom-prefix" custom-paths.txt
          INVENTOR_PREFIX="$HOME/explicit-prefix" WINEPREFIX="$HOME/custom-prefix" ${inventor}/bin/inventor-on-linux paths > explicit-paths.txt
          grep -F "prefix=$HOME/explicit-prefix" explicit-paths.txt
          mkdir -p "$HOME/existing-prefix"
          echo sentinel > "$HOME/existing-prefix/keep"
          if INVENTOR_PREFIX="$HOME/existing-prefix" ${inventor}/bin/inventor-on-linux init-prefix > refusal.txt 2>&1; then
            echo 'init-prefix unexpectedly accepted a nonempty directory' >&2
            exit 1
          fi
          grep -q 'Refusing to initialize a nonempty prefix' refusal.txt
          test "$(cat "$HOME/existing-prefix/keep")" = sentinel
          ${inventor}/bin/inventor-on-linux prepare-media --help
          # URI handlers are launched directly by the desktop, without the wrapper.
          bash -c 'set -eu; source ${inventor}/share/inventor-on-linux/scripts/common.sh; test "$INVENTOR_RUNNER" = "${runner}"; test "$state_dir" = "$HOME/.local/state/inventor-on-linux"'
          touch "$out"
        '';
      };
    };
}
