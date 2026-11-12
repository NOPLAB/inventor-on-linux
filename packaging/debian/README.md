# Debian package

Build an `amd64` package containing the toolkit, patched Wine Staging 11.8,
DXVK 2.7.1, Wine Mono, Wine Gecko, and IPAex fonts. The installed package runs
without Nix. Autodesk software and licenses must be obtained separately.

The builder uses Ubuntu 24.04 and targets its library ABI. Package installation,
prefix creation, and MSXML regression checks passed on Ubuntu 24.04 and Debian 13.
Runtime requirements
include glibc 2.39 or newer, Vulkan drivers, and the dependencies recorded in the
package. Validate installation on each target distribution before publishing a
release for it.

## Build

On an x86_64 Linux host with Docker:

```bash
./packaging/debian/build-docker.sh
```

Set `BUILD_JOBS` to limit compiler parallelism (default 8). Sources are downloaded
with pinned SHA-256 checksums. Download and compilation caches are stored under
`build/debian-downloads/` and `build/debian/`. The build produces:

- `build/debian/inventor-on-linux_0.1.0_amd64.deb`
- `build/debian/inventor-on-linux_0.1.0_wine-source.tar.xz`

The source archive contains the Wine source with staging and project patches,
the staging patch set, project patches, and packaging recipes. Retain it with the
binary when distributing the package, together with the project repository and
applicable third-party license notices.

## Install and configure

```bash
sudo apt install ./inventor-on-linux_0.1.0_amd64.deb
inventor-on-linux paths
inventor-on-linux init-prefix
```

For an existing dedicated prefix, set `INVENTOR_PREFIX` in
`~/.config/inventor-on-linux/config.sh` and skip `init-prefix`. Continue with
media preparation and installation as described in the root [README](../../README.md).
The package stores the runner under `/opt/inventor-on-linux/` and toolkit scripts
under `/usr/share/inventor-on-linux/`. Prefixes, downloaded media, logs, and
credentials are kept in the user's home directory.

This package includes the experimental WinVerifyTrust bypass described in the
root README. Use a dedicated prefix.

Installing a local `.deb` is supported by APT. A hosted APT repository requires
separate publication of package indexes and signing metadata.

## Verify the package

```bash
./packaging/debian/check-docker.sh
```

This installs the package and its runtime dependencies in a fresh Ubuntu 24.04
container, creates a prefix under Xvfb, checks both DXVK architectures, and runs
the existing MSXML attribute regression test as 64-bit and 32-bit Windows
executables. Set `TEST_IMAGE` to test another compatible distribution image.
Inventor GUI operation and GPU rendering require separate desktop validation.

Debian 13 can be checked with:

```bash
TEST_IMAGE=debian:13 ./packaging/debian/check-docker.sh
```
