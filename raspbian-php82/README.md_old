# PHP 8.2.35 for Raspbian 12 (Bookworm) ARMHF

**Status: TEMPLATE / NOT YET RELEASED.** No binaries are included. Do not advertise this project as a patched release until packages are built, verified and tested on a separate Raspberry Pi.

## Purpose

Distribute PHP 8.2.35 Debian packages built on Raspbian 12 armhf, including `php8.2-cli`, `php8.2-common`, `php8.2-opcache`, `php8.2-readline`, and `libapache2-mod-php8.2` when built by the source package. Other PHP modules must be included if needed by target machines.

## Build

1. Use a disposable Raspbian 12 armhf build system with enough RAM, disk and swap.
2. Configure an appropriate, trusted `deb-src` repository containing the **8.2.35** source package. Do not mix Debian binary repositories into Raspbian without compatibility testing.
3. Run `./build.sh`. It installs build dependencies, downloads the source, and builds DEBs.
4. Review package versions, dependencies, provenance, and any patch/backport information. Build all required modules; test on a separate Pi with the same OS/architecture.
5. Publish all required `.deb` files and the generated `SHA256SUMS` together in GitHub Release `v8.2.35-raspbian12-armhf-1`.
6. Replace `OWNER` in `install.sh` with your GitHub username before publishing.

**Note:** The build script is a starting point and needs an accessible, compatible source repository. It has not been run or validated here. Debian security packages may have a different version format than the upstream 8.2.35 release; check source package availability and packaging version first.

## Install

Download and inspect `install.sh` from the repository, then run:

```bash
sudo REPO=YOURNAME/raspbian-php82 bash ./install.sh
```

The installer verifies the target OS and architecture, downloads checksummed release DEBs, validates package metadata, backs up configuration, simulates APT changes, requests confirmation, installs, and restarts Apache if active.

## Security limitations

SHA256SUMS downloaded from the **same release** detect accidental corruption but **do not authenticate the publisher**. For public production use, sign the manifest with minisign/GPG or publish pinned hashes in a trusted channel and verify signatures before installing. Inspect the script and review the APT dry run. A config backup is not a complete package rollback. Preserve earlier DEBs and test rollback separately. Packages are not automatically updated by APT without a signed APT repository. Security support requires rebuilding and republishing subsequent fixes.

## Compatibility

Only Raspbian 12 Bookworm `armhf`. Matching architecture alone is not sufficient; runtime dependencies, extensions, Apache ABI, and system libraries must also match. Not for Raspberry Pi OS 64-bit (`arm64`).

## Verify

```bash
php -v
apache2ctl -M | grep php
sudo apache2ctl configtest
```

Check the PHP version served by Apache separately from the CLI version. Remove any temporary PHP diagnostic page after checking.
