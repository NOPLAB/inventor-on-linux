# Wine compatibility patches

Patch filenames use the component name followed by a description of the change.
The build definitions select and apply them to Wine Staging 11.8.

The comctl32-statusbar, ntdll-actctx, rpcrt4-ndrstubcall3 and combase-stub-activation-context patches are copied without changes from:
https://github.com/Harvi654/Autodesk-Inventor-for-Linux
commit 7d4c1e4a460400798159ef8a27e2b00dece3d61f.

They modify Wine and are licensed LGPL-2.1-or-later (COPYING.LIB).
See upstream docs/arch-hyprland.md for observations and reproduction details.
The two oleaut32-typedesc patches are from the same upstream commit and license.

The locally authored `wintrust-bypass-verification.patch` and
`msxml3-nodemap-return-inserted.patch` also modify Wine and are distributed under
LGPL-2.1-or-later. The project root's MIT license does not apply to these patches.

All patches are applied against Wine Staging 11.8 by the Nix derivations in
`flake.nix`. The locked Nixpkgs source supplies the original Wine sources, staging
patch set and source hashes. No Autodesk source code is included.
