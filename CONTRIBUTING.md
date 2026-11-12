# Development and validation

Contribute changes to original project code under the MIT license. Changes to
Wine patches are LGPL-2.1-or-later; retain their provenance and copyright notices.
Do not add Autodesk files or account information.

```bash
nix flake check -L --cores 8 --max-jobs 1
nix build .#inventor-on-linux --out-link result-package
./result-package/bin/inventor-on-linux --help
```

`flake check` validates shell and Python syntax, package help, configuration,
prefix selection, refusal to initialize a nonempty prefix, and the media
preparation CLI. It does not automatically test the Inventor GUI, authentication,
or analysis. Regular CI checks syntax; Nix checks, which can require expensive
Wine builds, run through a manual workflow trigger.

For Wine API regression checks, use the built `result` runner (`nix build
.#runner`) and a development X session:

```bash
./scripts/test-api.sh
./scripts/test-actctx.sh
./scripts/test-msxml-attribute.sh
```

These scripts use `test-prefix/`. For `test-inventor-typelib.sh`, explicitly set
`INVENTOR_PREFIX` to a diagnostic prefix with Inventor installed. Do not run tests
against your working prefix. Development tools such as `tests/inventor-commands.c`
and `tests/wine-dialog.c` can manipulate documents and dialogs.

When adding a patch, check the target DLLs and architectures in `flake.nix`, and
include a minimal reproduction and validation results. Report successful mesh
generation separately from the accuracy of analysis results.

Before publishing, inspect the staged files with `git diff --cached --stat`.
`build/`, `logs/`, `test-prefix/`, `config.local.sh`, crash dumps, CAD models, and
installers are not distribution artifacts.
