#!/usr/bin/env bash
# PHP 8.2.35 for Raspbian 12 Bookworm ARMHF (Apache mod_php)
set -Eeuo pipefail

REPO="OE9SAU/SVXLink_Git"
TAG="php8.2.35-rpi11"
VERSION="8.2.35-1~deb12u1+rpi11"
ASSET_VERSION="${VERSION/\~/.}"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

fail() { printf 'FEHLER: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }

[[ $(id -u) -eq 0 ]] || fail "Bitte mit sudo ausführen: sudo bash install.sh"
[[ -r /etc/os-release ]] || fail "Betriebssystem nicht erkennbar."
# shellcheck disable=SC1091
source /etc/os-release
[[ ${VERSION_ID:-} == 12 ]] || fail "Nur Debian/Raspbian 12 (Bookworm) unterstützt."
[[ ${VERSION_CODENAME:-} == bookworm ]] || fail "Nur Bookworm unterstützt."
[[ $(dpkg --print-architecture) == armhf ]] || fail "Nur ARMHF (32 Bit) unterstützt."
for cmd in curl sha256sum apt-get dpkg-deb tar; do
  command -v "$cmd" >/dev/null || fail "Benötigtes Programm fehlt: $cmd"
done

packages=(
  "php8.2-common_${ASSET_VERSION}_armhf.deb"
  "php8.2-cli_${ASSET_VERSION}_armhf.deb"
  "php8.2-opcache_${ASSET_VERSION}_armhf.deb"
  "php8.2-readline_${ASSET_VERSION}_armhf.deb"
  "libapache2-mod-php8.2_${ASSET_VERSION}_armhf.deb"
  "php8.2_${ASSET_VERSION}_all.deb"
)

workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT
cd "$workdir"

info "Lade SHA256SUMS und sechs DEB-Pakete herunter"
curl --fail --location --show-error --silent --retry 3 --output SHA256SUMS "${BASE_URL}/SHA256SUMS"
for pkg in "${packages[@]}"; do
  info "Lade $pkg"
  curl --fail --location --show-error --silent --retry 3 --output "$pkg" "${BASE_URL}/${pkg}"
done

info "Prüfe SHA256-Prüfsummen"
# GitHub hat beim Upload '~' in Asset-Dateinamen durch '.' ersetzt.
# Die Prüfsummen selbst bleiben unverändert; nur die Dateinamen werden angepasst.
sed -i 's/~deb12u1/.deb12u1/g' SHA256SUMS
sha256sum --check --strict SHA256SUMS || fail "Prüfsummenprüfung fehlgeschlagen. Keine Installation."

info "Prüfe Paket-Metadaten"

for pkg in "${packages[@]}"; do
  actual_version=$(dpkg-deb -f "$pkg" Version)

  [[ "$actual_version" == "$VERSION" ]] || \
    fail "Unerwartete Version in $pkg: $actual_version (erwartet: $VERSION)"
done

info "APT-Installationssimulation"
local_packages=()
for pkg in "${packages[@]}"; do local_packages+=("./${pkg}"); done
apt-get -s install "${local_packages[@]}" || fail "APT-Simulation fehlgeschlagen."

printf '\nDie Pakete werden nun installiert. Fortfahren? [j/N] '
read -r reply
[[ $reply == j || $reply == J || $reply == ja || $reply == JA ]] || { echo "Abgebrochen."; exit 0; }

info "Sichere vorhandene Apache- und PHP-Konfiguration"
backup_dir="/var/backups/php82"
backup_file="${backup_dir}/apache-php-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"
backup_paths=()
[[ -d /etc/apache2 ]] && backup_paths+=(apache2)
[[ -d /etc/php ]] && backup_paths+=(php)
if (( ${#backup_paths[@]} > 0 )); then
  install -d -m 0700 "$backup_dir"
  tar -C /etc -czf "$backup_file" "${backup_paths[@]}" || fail "Backup fehlgeschlagen. Installation abgebrochen."
  chmod 0600 "$backup_file"
  tar -tzf "$backup_file" >/dev/null || fail "Backup-Archiv ungültig. Installation abgebrochen."
  info "Backup erstellt: $backup_file"
else
  info "Keine vorhandenen Verzeichnisse /etc/apache2 oder /etc/php gefunden; kein Konfigurationsbackup erforderlich."
fi

info "Installiere PHP 8.2.35"
apt-get install "${local_packages[@]}"

info "Prüfe PHP CLI"
php -v | head -n 1
if command -v apache2ctl >/dev/null; then
  info "Prüfe Apache-Konfiguration"
  apache2ctl configtest
  if command -v systemctl >/dev/null && systemctl is-active --quiet apache2; then
    systemctl restart apache2
    info "Apache neu gestartet"
  fi
fi
info "Fertig. Bitte Apache-PHP-Version und Webanwendungen ebenfalls testen."

