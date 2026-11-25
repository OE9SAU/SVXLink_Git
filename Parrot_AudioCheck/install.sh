#!/bin/bash

set -euo pipefail

VERSION="1.02"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:---check}"

MOD="/usr/lib/arm-linux-gnueabihf/svxlink/ModuleParrot.so"
CONF="/etc/svxlink/svxlink.d/ModuleParrot.conf"
EVENTS="/usr/share/svxlink/events.d/local"
SOUNDS="/usr/share/svxlink/sounds/de_DE/Parrot"

WAV_FILES=(
    level_very_low.wav
    level_low.wav
    level_ok.wav
    level_high.wav
    level_very_high.wav
    test_invalid.wav
)

fail()
{
    echo "ERROR: $*" >&2
    exit 1
}

case "$MODE" in
    --check|--install) ;;
    *)
        echo "Usage: sudo $0 --check|--install"
        exit 1
        ;;
esac

[[ $EUID -eq 0 ]] || fail "Please run with sudo."

cd "$ROOT"

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT

echo "=========================================="
echo " SVXLink Parrot AudioCheck V$VERSION"
echo " Installer"
echo "=========================================="

echo
echo "=== Checking dependencies ==="

for CMD in python3 tclsh sha256sum systemctl install cmp ldd flock
do
    command -v "$CMD" >/dev/null \
        || fail "Missing command: $CMD"
done

exec 9>/run/lock/svxlink-parrot-audiocheck.lock
flock -n 9 || fail "Another installer is running"

echo
echo "=== Compatibility check ==="

./check-compatibility.sh

echo
echo "=== Verifying release checksums ==="

[[ -f SHA256SUMS ]] || fail "Release checksums missing"

sha256sum --strict -c SHA256SUMS \
    || fail "Release checksum verification failed"

echo "Release integrity: OK"

echo
echo "=== Checking installation files ==="

for FILE in \
    bin/armhf/ModuleParrot.so \
    events.d/local/Parrot-AudioCheck.tcl \
    update-config.py \
    update-tcl.py \
    backup.sh \
    rollback.sh
do
    [[ -f "$FILE" ]] || fail "Missing file: $FILE"
done

for FILE in "${WAV_FILES[@]}"
do
    [[ -f "sounds/de_DE/Parrot/$FILE" ]] \
        || fail "Missing sound file: $FILE"
done

EXPECTED_HASH="2c1f6bcffeed9a5080e13718f39be7d5dd744b990aff949a019c24a2f6636bc1"

echo "$EXPECTED_HASH  bin/armhf/ModuleParrot.so" \
    | sha256sum -c -

ldd bin/armhf/ModuleParrot.so > "$WORK/ldd.txt"
cat "$WORK/ldd.txt"

if grep -q "not found" "$WORK/ldd.txt"; then
    fail "Missing shared libraries"
fi

echo
echo "=== Checking destination files ==="

for FILE in "$MOD" "$CONF" \
    "$EVENTS/Parrot.tcl" \
    "$EVENTS/Parrot-AudioCheck.tcl"
do
    [[ ! -L "$FILE" ]] \
        || fail "Symbolic link not supported: $FILE"
done

for FILE in "${WAV_FILES[@]}"
do
    [[ ! -L "$SOUNDS/$FILE" ]] \
        || fail "Symbolic link not supported: $FILE"
done

if [[ -e "$EVENTS/Parrot-AudioCheck.tcl" ]]; then
    fail "Separate local AudioCheck TCL file already exists"
fi

echo
echo "=== Preparing configuration ==="

./update-config.py \
    "$CONF" \
    "$WORK/ModuleParrot.conf"

echo
echo "=== Preparing TCL event handlers ==="

./update-tcl.py \
    "$EVENTS/Parrot.tcl" \
    events.d/local/Parrot-AudioCheck.tcl \
    "$WORK/Parrot.tcl"

echo
echo "=== Configuration preview ==="

cat "$WORK/ModuleParrot.conf"

echo
echo "=== Installation plan ==="

echo "Module:        $MOD"
echo "Configuration: $CONF"
echo "TCL:           $EVENTS/Parrot.tcl"
echo "Sounds:        $SOUNDS"
echo "Version:       $VERSION"

echo
echo "Pre-installation checks: OK"

if [[ "$MODE" == "--check" ]]; then
    echo "Check only. No SVXLink files changed."
    exit 0
fi

echo
read -r -p "Install AudioCheck V$VERSION? Type YES: " ANSWER

[[ "$ANSWER" == "YES" ]] \
    || fail "Installation cancelled"

echo
echo "=== Creating backup ==="

./backup.sh | tee "$WORK/backup.log"

BACKUP="$(tail -n 1 "$WORK/backup.log")"

./rollback.sh --check "$BACKUP"

WAS_ACTIVE=0

if systemctl is-active --quiet svxlink; then
    WAS_ACTIVE=1
fi

installation_failed()
{
    echo
    echo "ERROR: Installation failed."
    echo "Backup: $BACKUP"
    echo "Check service status before restoring."
    echo "Restore with:"
    echo "sudo $ROOT/rollback.sh --restore $BACKUP"
}

trap installation_failed ERR

echo
echo "=== Stopping SVXLink ==="

systemctl stop svxlink

echo
echo "=== Installing module ==="

install -o root -g root -m 644 \
    bin/armhf/ModuleParrot.so "$MOD"

echo
echo "=== Installing configuration ==="

cp -- "$WORK/ModuleParrot.conf" "$CONF"

echo
echo "=== Installing TCL event handlers ==="

mkdir -p "$EVENTS"

if [[ -f "$EVENTS/Parrot.tcl" ]]; then
    cp -- "$WORK/Parrot.tcl" "$EVENTS/Parrot.tcl"
else
    install -o root -g root -m 644 \
        "$WORK/Parrot.tcl" "$EVENTS/Parrot.tcl"
fi

echo
echo "=== Installing sound files ==="

mkdir -p "$SOUNDS"

for FILE in "${WAV_FILES[@]}"
do
    install -o root -g root -m 644 \
        "sounds/de_DE/Parrot/$FILE" \
        "$SOUNDS/$FILE"
done

echo
echo "=== Verifying installed files ==="

cmp bin/armhf/ModuleParrot.so "$MOD"
cmp "$WORK/ModuleParrot.conf" "$CONF"
cmp "$WORK/Parrot.tcl" "$EVENTS/Parrot.tcl"

for FILE in "${WAV_FILES[@]}"
do
    cmp "sounds/de_DE/Parrot/$FILE" "$SOUNDS/$FILE"
    echo "OK: $FILE"
done

if [[ "$WAS_ACTIVE" -eq 1 ]]; then
    echo
    echo "=== Starting SVXLink ==="

    systemctl start svxlink
    sleep 3
    systemctl is-active --quiet svxlink
fi

trap - ERR

echo
echo "=========================================="
echo " AudioCheck V$VERSION installed"
echo "=========================================="
echo
echo "Backup: $BACKUP"
echo
echo "Rollback command:"
echo "sudo $ROOT/rollback.sh --restore $BACKUP"
