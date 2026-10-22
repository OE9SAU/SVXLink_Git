#!/usr/bin/env bash
set -Eeuo pipefail
# Builds Debian's security-patched php8.2 source package on native Raspbian 12 armhf.
# Requires a source repository that actually provides php8.2 8.2.35.
source /etc/os-release
[[ ${ID:-} == raspbian && ${VERSION_CODENAME:-} == bookworm ]] || { echo 'Requires Raspbian 12'; exit 1; }
[[ $(dpkg --print-architecture) == armhf ]] || { echo 'Requires armhf'; exit 1; }
[[ $(id -u) -ne 0 ]] || { echo 'Run build.sh as an unprivileged user with sudo access.'; exit 1; }
command -v apt-get >/dev/null
sudo apt-get update
sudo apt-get install -y build-essential devscripts dpkg-dev fakeroot equivs ca-certificates
mkdir -p "$HOME/php82-build"; cd "$HOME/php82-build"
# Source repositories must be configured explicitly by the builder.
apt-cache showsrc php8.2 > source-metadata.txt || { echo 'Enable a trusted deb-src source for php8.2 first.'; exit 1; }
if ! grep -q '^Version: 8\.2\.35' source-metadata.txt; then
  echo 'No php8.2 8.2.35 source package in configured source repositories.' >&2; exit 1
fi
source_version=$(awk '/^Version: 8\.2\.35([^-[:space:]]|-[^[:space:]])*/ {print $2; exit}' source-metadata.txt)
[[ -n "$source_version" ]] || { echo 'Cannot resolve source version'; exit 1; }
apt-get source "php8.2=$source_version" || { echo 'Source download failed'; exit 1; }
source_dir=$(find . -maxdepth 1 -type d -name 'php8.2-*' | head -n1)
[[ -n "$source_dir" ]] || exit 1
cd "$source_dir"
sudo mk-build-deps --install --remove --tool 'apt-get -y' debian/control
DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-nocheck}" dpkg-buildpackage -us -uc -b -j"$(nproc)"
mkdir -p ../release
cp ../*.deb ../release/
(cd ../release && sha256sum ./*.deb > SHA256SUMS)
echo "Packages and checksums: $HOME/php82-build/release"
