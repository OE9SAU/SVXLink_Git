#!/bin/bash

set -euo pipefail

VERSION="1.10"
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
echo "=== Verifying release checksums ==="

[[ -f SHA256SUMS ]] || fail "Release checksums missing"

sha256sum --strict -c SHA256SUMS \
    || fail "Release checksum verification failed"

echo "Release integrity: OK"

echo
echo "=== Compatibility check ==="

./check-compatibility.sh

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

EXPECTED_HASH="0ea27384bd3ea0fac8bc0cdeb20c2aeafa57a8bf0adef3ed31e633a92e3bd4b5"

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

LOGFILE=""
LOG_OFFSET=0
LOG_INODE=""

if [[ "$WAS_ACTIVE" -eq 1 ]]; then
    PID="$(systemctl show svxlink -p MainPID --value)"
    LOGFILE="$(tr "\\0" "\\n" < "/proc/$PID/cmdline" | sed -n "s/^--logfile=//p")"

    if [[ -n "$LOGFILE" && -f "$LOGFILE" ]]; then
        LOG_OFFSET="$(stat -c %s "$LOGFILE")"
        LOG_INODE="$(stat -c %d:%i "$LOGFILE")"
        echo "Logfile: $LOGFILE"
        echo "Log offset: $LOG_OFFSET"
        echo "Log inode: $LOG_INODE"
    else
        echo "WARNING: Unable to determine SVXLink logfile."
    fi
fi

installation_failed()
{
    trap - ERR
    trap "" INT TERM
    echo ""
    echo "ERROR: Installation failed."
    echo "Starting automatic rollback ..."
    echo "Backup: $BACKUP"

    if "$ROOT/rollback.sh" --restore-auto "$BACKUP"; then
        echo "Automatic rollback: OK"
    else
        echo "ERROR: Automatic rollback failed."
        echo "Manual recovery required:"
        echo "sudo $ROOT/rollback.sh --restore $BACKUP"
    fi

    exit 1
}

trap installation_failed ERR
trap installation_failed INT TERM

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
    echo "=== Monitoring SVXLink for 30 seconds ==="
    PID="$(systemctl show svxlink -p MainPID --value)"
    [[ "$PID" =~ ^[1-9][0-9]*$ ]] || installation_failed

    for ((i=1; i<=15; i++)); do
        sleep 2
        systemctl is-active --quiet svxlink || installation_failed
        CURRENT_PID="$(systemctl show svxlink -p MainPID --value)"
        [[ "$CURRENT_PID" == "$PID" ]] || installation_failed
        echo "Service stability: $((i * 2))/30 seconds OK"
    done

    echo "SVXLink service stability: OK"

    echo "=== Checking AudioCheck initialization ==="

    if grep -Eq "^[[:space:]]*AUDIOCHECK[[:space:]]*=[[:space:]]*1[[:space:]]*$" "$CONF"; then
        [[ -n "$LOGFILE" && -f "$LOGFILE" ]] || installation_failed
        [[ "$(stat -c %d:%i "$LOGFILE")" == "$LOG_INODE" ]] || installation_failed
        [[ "$(stat -c %s "$LOGFILE")" -ge "$LOG_OFFSET" ]] || installation_failed

        tail -c "+$((LOG_OFFSET + 1))" "$LOGFILE" > "$WORK/startup.log"

        grep -F "Parrot: AudioCheck V1.10 initialisiert" "$WORK/startup.log" || installation_failed
        grep -F "Parrot: Abtastrate: 16000 Hz" "$WORK/startup.log" || installation_failed

        echo "AudioCheck initialization: OK"
    else
        echo "WARNING: AudioCheck initialization not verified (AUDIOCHECK=1 not detected)."
    fi
fi

trap - ERR INT TERM

echo
echo "=========================================="
echo " AudioCheck V$VERSION installed"
echo "=========================================="
echo
echo "Backup: $BACKUP"
echo
echo "Rollback command:"
echo "sudo $ROOT/rollback.sh --restore $BACKUP"
