#!/usr/bin/env bash
set -Eeuo pipefail
VERSION=8.2.35
REPO="${REPO:-OWNER/raspbian-php82}"
TAG="${TAG:-v${VERSION}-raspbian12-armhf-1}"
BASE="https://github.com/${REPO}/releases/download/${TAG}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail(){ echo "ERROR: $*" >&2; exit 1; }
[[ $(id -u) -eq 0 ]] || fail 'Run with sudo.'
source /etc/os-release
[[ ${ID:-} == raspbian && ${VERSION_CODENAME:-} == bookworm ]] || fail 'Requires Raspbian 12 Bookworm.'
[[ $(dpkg --print-architecture) == armhf ]] || fail 'Requires armhf.'
[[ "$REPO" != OWNER/* ]] || fail 'Repository not configured. Set REPO=yourname/raspbian-php82 after publishing.'
for cmd in curl sha256sum dpkg-deb apt-get tar; do command -v "$cmd" >/dev/null || fail "Missing $cmd"; done
mkdir -p "$WORK/packages"
echo "Downloading release manifest from $BASE"
curl --fail --location --silent --show-error --retry 3 "$BASE/SHA256SUMS" -o "$WORK/SHA256SUMS"
# Only explicitly formatted filenames; avoid path traversal and shell injection.
mapfile -t files < <(awk '{print $2}' "$WORK/SHA256SUMS")
((${#files[@]} > 0)) || fail 'Empty checksum manifest.'
for name in "${files[@]}"; do
  [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9.+_~-]*\.deb$ ]] || fail "Invalid filename: $name"
  curl --fail --location --silent --show-error --retry 3 "$BASE/$name" -o "$WORK/packages/$name"
done
(cd "$WORK/packages" && sha256sum -c "$WORK/SHA256SUMS") || fail 'Checksum mismatch.'
for f in "$WORK"/packages/*.deb; do
  [[ $(dpkg-deb -f "$f" Architecture) == armhf || $(dpkg-deb -f "$f" Architecture) == all ]] || fail "Architecture mismatch: $f"
  pkg=$(dpkg-deb -f "$f" Package)
  [[ "$pkg" == php8.2* || "$pkg" == libapache2-mod-php8.2 ]] || fail "Unexpected package: $pkg"
  ver=$(dpkg-deb -f "$f" Version)
  [[ "$ver" == "$VERSION"* ]] || fail "Unexpected version $ver"
done
BACKUP="/root/php82-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
paths=(); [[ -d /etc/php/8.2 ]] && paths+=(etc/php/8.2); [[ -d /etc/apache2 ]] && paths+=(etc/apache2)
((${#paths[@]} == 0)) || tar -C / -czf "$BACKUP" "${paths[@]}"
echo "Configuration backup: $BACKUP"
echo 'APT dry-run (review changes):'
apt-get -s install "$WORK"/packages/*.deb
read -r -p 'Proceed with installation? [y/N] ' reply
[[ "$reply" =~ ^[Yy]$ ]] || exit 0
apt-get install "$WORK"/packages/*.deb
if command -v apache2ctl >/dev/null && systemctl is-active --quiet apache2; then
  apache2ctl configtest
  systemctl restart apache2
fi
php -v
