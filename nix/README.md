# Using the Nix package

The supported system is `x86_64-linux`. Run or install the public flake:

```bash
nix run github:NOPLAB/inventor-on-linux -- --help
nix build github:NOPLAB/inventor-on-linux#inventor-on-linux
nix profile add github:NOPLAB/inventor-on-linux#inventor-on-linux
```

Use `.` or an absolute checkout path instead of `github:NOPLAB/inventor-on-linux` to use local changes.

## NixOS and Home Manager

```nix
{
  inputs.inventor-on-linux.url = "github:NOPLAB/inventor-on-linux";

  outputs = { self, nixpkgs, inventor-on-linux, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          inventor-on-linux.packages.x86_64-linux.inventor-on-linux
        ];
      }];
    };
  };
}
```

Add the input and package to your existing flake. Home Manager can reference the same package in `home.packages`. An `overlays.default` output is also available. The runner stays pinned to the tested Nixpkgs revision even when using the overlay. Avoid overriding `inputs.nixpkgs.follows` without checking Wine DLL ABI compatibility.

## Outputs

| Output | Contents |
| --- | --- |
| `packages.x86_64-linux.default` / `inventor-on-linux` | CLI, desktop entry, and references to the runner and setup dependencies |
| `packages.x86_64-linux.runner` | Patched Wine runner |
| `packages.x86_64-linux.wintrust` | Patched wintrust and related DLLs; not a standalone runner |
| `packages.x86_64-linux.window-shape` | X11 window resize helper |
| `packages.x86_64-linux.media-tools` | Python and 7-Zip |
| `packages.x86_64-linux.fonts` | IPAex fonts |
| `packages.x86_64-linux.dxvk` | DXVK 32-bit / 64-bit DLLs |
| `apps.x86_64-linux.default` / `inventor-on-linux` | `nix run` entry point |

The package contains no Autodesk software or credentials. Media preparation and installation run as user commands, outside the Nix build, using official media you provide.

## Configuration and setup

Put persistent configuration in `~/.config/inventor-on-linux/config.sh` (`XDG_CONFIG_HOME` is respected):

```bash
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-$HOME/.local/share/inventor-on-linux/prefix}"
# export INVENTOR_BROWSER=firefox
```

Without an explicit setting, the toolkit uses `WINEPREFIX` if set, otherwise `$XDG_DATA_HOME/inventor-on-linux/prefix` (default `~/.local/share/inventor-on-linux/prefix`). Use a dedicated 64-bit prefix. Bottles is optional; an existing frontend-managed prefix can be selected by its absolute path.

Package state (media, logs, backups) lives in `$XDG_STATE_HOME/inventor-on-linux`, defaulting to `~/.local/state/inventor-on-linux`. Override it with `INVENTOR_STATE_DIR`. Source scripts default to the checkout for state. `inventor-on-linux paths` prints effective paths.

From a graphical desktop session, create a new standalone prefix and install:

```bash
inventor-on-linux init-prefix
inventor-on-linux prepare-media /absolute/path/to/extracted-media
inventor-on-linux install --dry-run
inventor-on-linux install
inventor-on-linux repair-vc-runtime
inventor-on-linux disable-addins
inventor-on-linux setup-fonts
inventor-on-linux setup-browser
inventor-on-linux launch
```

`init-prefix` uses matching stock Wine to create a 64-bit Windows 10 prefix, then installs DXVK. It refuses nonempty directories. For an existing dedicated prefix, skip initialization and use `setup-dxvk` if needed after closing its applications. Only Bottles users need the optional `register-runner` command.

See the root [README](../README.md) for media requirements, compatibility limitations, and the distinction between the tested Bottles environment and the standalone setup path. Run `setup-browser` again after package upgrades to refresh desktop callback paths.
