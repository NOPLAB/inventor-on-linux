# inventor-on-linux

An experimental Wine runner and setup toolkit for **Autodesk Inventor Professional 2027, Japanese edition**, on Linux. Nix pins Wine Staging 11.8 and builds the compatibility patches. You can use a standalone Wine prefix or a dedicated prefix managed by Bottles or another Wine frontend. **Bottles is optional.**

The Japanese UI, Autodesk ID sign-in, sketching, extrusion, the stress analysis environment, and mesh generation in a new study have been tested. **Solver execution and the accuracy of analysis results have not been verified.** See [VALIDATION.md](VALIDATION.md) for the tested configuration. This project is not supported by Autodesk.

## Requirements

- x86_64 Linux with Nix and `flakes` / `nix-command` enabled. Testing has used NixOS, KDE, and XWayland; native Wayland is untested.
- A Vulkan-capable GPU and working drivers. The standalone setup installs DXVK for Direct3D 11. The existing Bottles configuration also used VKD3D; the standalone setup does not install VKD3D or claim Direct3D 12 support.
- Official Inventor 2027 installation media, an Autodesk ID, and a valid entitlement.
- A native browser, `xdg-open`, `xdg-mime`, `update-desktop-database`, internet access, and enough disk space for Wine builds and installation media. The Nix package supplies the desktop integration utilities.

Inventor binaries, installation media, licenses, and credentials are not included. The standalone initialization path is covered separately from the existing Bottles validation; a complete clean installation and Inventor GUI session on that path still require validation.

## Install the toolkit

```bash
git clone https://github.com/NOPLAB/inventor-on-linux.git
cd inventor-on-linux
nix build .#inventor-on-linux --out-link result-package
./result-package/bin/inventor-on-linux --help
```

The following examples assume the CLI is on your `PATH`:

```bash
nix profile add .#inventor-on-linux
```

Alternatively, run `./result-package/bin/inventor-on-linux` or `nix run . --` in place of `inventor-on-linux`. See [the Nix package guide](nix/README.md) for flake inputs, NixOS, Home Manager, and individual outputs.

## Debian and Ubuntu packages

For a deb package that runs without Nix, see the [Debian package guide](packaging/debian/README.md). It includes a native Wine build and the setup dependencies.

## Configure a dedicated Wine prefix

The default prefix is `$XDG_DATA_HOME/inventor-on-linux/prefix`, or `~/.local/share/inventor-on-linux/prefix`. `INVENTOR_PREFIX` overrides it; otherwise an existing `WINEPREFIX` environment variable is respected.

If you used the previous Bottles-based default, explicitly configure that existing bottle's path to keep using it.

For persistent settings, create `~/.config/inventor-on-linux/config.sh` (`XDG_CONFIG_HOME` is respected):

```bash
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-$HOME/.local/share/inventor-on-linux/prefix}"
# Optional: executable name or absolute path, without arguments.
# export INVENTOR_BROWSER=firefox
```

Use an absolute prefix path. Keep this setting in the configuration file when using browser sign-in: desktop callbacks do not inherit environment variables from the launching terminal. `INVENTOR_CONFIG` selects an alternate configuration file for CLI invocations; desktop callbacks must also be able to find the settings in the default configuration file.

```bash
inventor-on-linux paths
inventor-on-linux init-prefix
```

`init-prefix` creates a 64-bit prefix using the runner's matching stock Wine, selects Windows 10, and installs both architectures of DXVK from the pinned Nixpkgs package. It refuses to initialize a nonempty directory or a symbolic link. Run it from a graphical desktop session. After initialization, commands use the patched runner directly; no Wine frontend is needed.

To use an existing dedicated 64-bit prefix from Bottles, Lutris, or another frontend, set `INVENTOR_PREFIX` to its absolute path and skip `init-prefix`. Close that prefix's applications before installing DXVK if needed:

```bash
inventor-on-linux setup-dxvk
```

Use the patched runner for installation and launch. A frontend's normal system Wine will not provide these compatibility fixes. The CLI does not read frontend settings such as environment variables or DLL overrides; put required settings in the toolkit configuration. Back up an existing prefix before changing it.

### Optional Bottles integration

Create a dedicated 64-bit bottle with Windows 10 and configure DXVK / VKD3D in Bottles. Set `INVENTOR_PREFIX` to its actual path; Flatpak Bottles uses different paths and sandbox permissions.

```bash
inventor-on-linux register-runner
```

Restart Bottles and select `inventor-unsafe-11.8` for this bottle. Registration refuses to overwrite an existing runner. To update, close the applications, move the previous runner aside, and register again. The copied runner references the local Nix store and is specific to this machine; keep its Nix package or build output rooted.

## Prepare official media and install

Obtain an extracted Autodesk installation image containing `setup.xml` and `manifest/app.*.xml`. The small `webinstall.exe` alone is not a complete image. An Autodesk installer may extract the image under `drive_c/Autodesk/WI/.../INVPROSA_2027_ja-JP` in a Wine prefix. Obtain media through Autodesk's official distribution methods.

```bash
inventor-on-linux prepare-media /absolute/path/to/extracted-media
inventor-on-linux install --dry-run
inventor-on-linux install
```

The toolkit copies the image to `build/install-media` under its state directory. Payloads referenced by the manifests are downloaded from Autodesk distribution servers and checked against their sizes and SHA-256 hashes. Downloads are cached in `build/payloads`. Run `prepare-media` without an argument to resume. Completed installation steps are recorded in the prefix's `.odis-install-state.json`.

The package stores media, logs, and backups in `$XDG_STATE_HOME/inventor-on-linux` (default `~/.local/state/inventor-on-linux`). Set `INVENTOR_STATE_DIR` to change this. Scripts run directly from the source tree default to the repository's `build/` and `logs/` directories.

Installation targets an initialized dedicated prefix, installs the Japanese edition, and skips Content Center. The 2027.2 update has not been tested. A successful installation in the original environment does not guarantee every clean installation will complete.

After installation, before launching Inventor:

```bash
inventor-on-linux repair-vc-runtime
inventor-on-linux disable-addins
inventor-on-linux setup-fonts
inventor-on-linux setup-browser
inventor-on-linux launch
```

VC runtime repair uses Microsoft VC++ 14.50.35719 from the installation cache and stops if the required CAB files are missing. SharedViews and InteractiveTutorial are moved aside because they crash under Wine Mono. Japanese font setup installs IPAex fonts from Nix. Save your work and restart Inventor if it is already running.

## Sign in and launch

`launch` starts Identity Manager and the real Autodesk Licensing Service, then Inventor. It creates the RealDWG initialization XML if missing. Set `INVENTOR_WINE_USER` if the Windows profile name differs from your Linux username.

`setup-browser` registers Linux handlers for `adskidmgr:` and `adsk.idmgr:` and configures WineBrowser in the selected prefix. Choose Autodesk ID sign-in, authenticate in the native browser, and allow the browser to open the callback. Run `setup-browser` again after moving the source tree or updating the Nix package so the desktop entry uses the current path. Callback URIs and authentication codes are not written to the callback log.

The default browser is Firefox when available, otherwise `xdg-open`. `INVENTOR_BROWSER` selects another executable without command-line arguments. Authentication and licensing are handled by Autodesk's software.

## Compatibility changes and limitations

- **WinVerifyTrust:** BLOB verification is treated as successful. The toolkit sets `INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1` to retain normal file verification errors. **Removing this variable also turns normal file verification failures into success. This weakens signature verification; use a dedicated prefix.** Patched DLLs are copied into the prefix and remain there after exit.
- **comctl32 / ntdll / rpcrt4 / combase:** compatibility fixes for status bar painting, activation contexts, and COM stubs.
- **oleaut32:** fixes Inventor type library metadata handling to avoid a crash when opening stress analysis.
- **msxml3 / msxml6:** changes the return value of `NamedNodeMap.setNamedItem` to preserve numeric mesh settings. Recreate studies made before this fix, including their constraints and loads.
- **X11 window helper:** clears a stale rectangular window mask when resizing or maximizing the main window. Set `INVENTOR_WINDOW_SHAPE_FIX=0` to disable automatic startup; `pkill -x inventor-shape` stops an existing helper.

For licensing installation failures, `repair-licensing` only proceeds when logs contain both `1053` and `LIC-INST-ERROR-69009748`, and the actual licensing service executable exists. Use it only after diagnosing that specific installation timeout:

```bash
inventor-on-linux repair-licensing
```

## Use scripts from the checkout

The same commands are available without installing the CLI package:

```bash
nix build .#runner -L --cores 8 --max-jobs 1
cp config.example.sh config.local.sh
# Edit config.local.sh to choose a dedicated prefix.
./scripts/inventor-on-linux.sh init-prefix
./scripts/inventor-on-linux.sh prepare-media /absolute/path/to/extracted-media
```

`config.local.sh` is ignored by Git and is also read by the source scripts. Other entry scripts remain available, including `launch-inventor.sh` and `install-cached-media.sh`. The checkout resolves media tools, fonts, and DXVK through the pinned flake as needed.

## Restore stock Wine

Save your work, close Inventor, and explicitly name the prefix to restore:

```bash
inventor-on-linux restore-prefix /absolute/path/to/dedicated-prefix
```

This stops Wine processes belonging to that prefix and restores backed-up `wintrust.dll` files. Select a stock runner in your frontend as well, if applicable. Font settings, DXVK installation (original DLLs saved as `.inventor-dxvk-original`), VC runtime repair, and disabled add-ins remain separate changes. Restore a prefix backup if you need to undo every change.

## Contributing and licenses

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands. Logs, models, media, and local settings are excluded from Git. Remove authentication URLs, tokens, and serial numbers from bug reports.

Original toolkit code is licensed under [MIT](LICENSE). **Patches modifying Wine are LGPL-2.1-or-later.** The imported installation tools retain their MIT notices. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [patch provenance](patches/README.md).
