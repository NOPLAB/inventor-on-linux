# Validation record

As of 2026-11-12, tested on NixOS / KDE / XWayland / Wine Staging 11.8 with
Autodesk Inventor Professional 2027, Japanese edition. These results come from a
single environment; other distributions and GPUs have not been tested.

| Feature | Result |
| --- | --- |
| Installation from official manifests | SHA-256 verified for 42 archives; 27 installation steps completed |
| Autodesk ID authentication | Callback between the native Linux browser and Identity Manager succeeded |
| Japanese UI, sketching, extrusion | Verified |
| Environments → Stress Analysis | Startup crash fixed; environment displayed successfully |
| Mesh generation in a new study | Generated and displayed 2,199 nodes and 1,258 elements |
| Structural analysis solver and result accuracy | **Not verified** |
| Window resizing and maximization | Display followed window size after the X11 Shape fix |
| Content Center and the 2027.2 update | Not installed or tested |

Regression checks include `scripts/test-api.sh` (comparison with an unsigned
file), `scripts/test-actctx.sh` (manifest threading models),
`scripts/test-msxml-attribute.sh` (four cases covering attribute insertion and
replacement in XML 3/6), and `scripts/test-inventor-typelib.sh` (requires an
Inventor installation). Use a test prefix; do not run diagnostics against your
working prefix.

Studies created before the MSXML fix may have numeric settings saved as zero.
Create a new study and recreate its constraints and loads.

The COM and dialog manipulation programs in `tests/` are development tools. They
can save or modify documents and manipulate dialogs; they are not needed for a
normal installation.

## Standalone Wine prefix setup

Tested separately on 2026-11-12 using the packaged CLI and a new temporary
prefix, without Bottles or changes to the working Inventor prefix:

- `init-prefix` completed with Wine Staging 11.8 and DXVK 2.7.1.
- Both `d3d11.dll` and `dxgi.dll` matched the pinned x64 payloads in `system32`
  and the x86 payloads in `syswow64`; original DLL backups were present.
- Registry queries confirmed Windows 10 and `native,builtin` overrides for
  `d3d11` and `dxgi`.
- `nix flake check` passed, including prefix selection and refusal to initialize
  a nonempty directory without modifying its contents.

A full clean Inventor installation, browser sign-in, and GUI session in this new
standalone prefix have not been tested. The Inventor feature results above were
obtained in the existing Bottles-managed prefix. Other frontends and GPUs remain
untested.
