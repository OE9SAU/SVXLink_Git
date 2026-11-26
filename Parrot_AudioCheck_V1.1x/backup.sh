#!/bin/bash

set -euo pipefail

MOD="/usr/lib/arm-linux-gnueabihf/svxlink/ModuleParrot.so"
CONF="/etc/svxlink/svxlink.d/ModuleParrot.conf"
EVENTS="/usr/share/svxlink/events.d/local"
SOUNDS="/usr/share/svxlink/sounds/de_DE/Parrot"

BACKUP_ROOT="/var/backups/svxlink-parrot-audiocheck-v1.1x"

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    exit 1
fi

umask 077
mkdir -p "$BACKUP_ROOT"

BACKUP="$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-XXXXXX")"

echo "=== Creating Parrot backup ==="

save_file()
{
    local FILE="$1"

    if [[ -e "$FILE" || -L "$FILE" ]]; then
        mkdir -p "$BACKUP$(dirname "$FILE")"
        cp -a -- "$FILE" "$BACKUP$FILE"
        printf 'PRESENT\t%s\n' "$FILE" >> "$BACKUP/manifest.txt"
    else
        printf 'ABSENT\t%s\n' "$FILE" >> "$BACKUP/manifest.txt"
    fi
}

save_file "$MOD"
sha256sum "$BACKUP$MOD" | awk '{print $1}' > "$BACKUP/Original-Module-SHA256.txt"
save_file "$CONF"
save_file "$EVENTS/Parrot.tcl"
save_file "$EVENTS/Parrot-AudioCheck.tcl"

for FILE in level_very_low.wav level_low.wav level_ok.wav \
            level_high.wav level_very_high.wav test_invalid.wav
do
    save_file "$SOUNDS/$FILE"
done

# Save service state before installation.
if systemctl is-active --quiet svxlink; then
    echo "active" > "$BACKUP/Service-State.txt"
else
    echo "inactive" > "$BACKUP/Service-State.txt"
fi

timeout -k 2s 10s svxlink --version > "$BACKUP/SVXLink-Version.txt"
dpkg --print-architecture > "$BACKUP/Architecture.txt"
cp /etc/os-release "$BACKUP/OS-Version.txt"

(
    cd "$BACKUP"

    find . -type f ! -name SHA256SUMS -print0 \
        | sort -z | xargs -0 sha256sum > SHA256SUMS

    echo
    echo "=== Verifying backup ==="
    sha256sum -c SHA256SUMS
)

echo
echo "Backup successfully created:"
echo "$BACKUP"
