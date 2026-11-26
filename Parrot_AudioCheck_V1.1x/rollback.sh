#!/bin/bash

set -euo pipefail

BACKUP_ROOT="/var/backups/svxlink-parrot-audiocheck-v1.1x"
MODE="${1:-}"
BACKUP="${2:-}"

fail()
{
    echo "ERROR: $*" >&2
    exit 1
}

[[ $EUID -eq 0 ]] || fail "Please run with sudo."

case "$MODE" in
    --check|--restore|--restore-auto) ;;
    *)
        echo "Usage:"
        echo "  sudo $0 --check BACKUP_DIRECTORY"
        echo "  sudo $0 --restore BACKUP_DIRECTORY"
        exit 1
        ;;
esac

[[ -n "$BACKUP" ]] || fail "No backup specified"
[[ -d "$BACKUP" ]] || fail "Backup not found"

BACKUP="$(realpath "$BACKUP")"

[[ "$(dirname "$BACKUP")" == "$BACKUP_ROOT" ]] \
    || fail "Invalid backup directory"

[[ -f "$BACKUP/manifest.txt" ]] \
    || fail "Manifest missing"

[[ -f "$BACKUP/SHA256SUMS" ]] \
    || fail "Checksums missing"

echo "=========================================="
echo " SVXLink Parrot AudioCheck V1.10"
echo " Rollback"
echo "=========================================="
echo
echo "Backup: $BACKUP"
echo

echo "=== Verifying backup ==="

(
    cd "$BACKUP"
    sha256sum -c SHA256SUMS
)

echo
echo "=== Checking backup compatibility ==="

[[ -f "$BACKUP/SVXLink-Version.txt" ]] \
    || fail "Saved SVXLink version missing"

[[ -f "$BACKUP/Architecture.txt" ]] \
    || fail "Saved architecture missing"

SAVED_VERSION="$(cat "$BACKUP/SVXLink-Version.txt")"
CURRENT_VERSION="$(timeout -k 2s 10s svxlink --version 2>&1)"

SAVED_ARCH="$(cat "$BACKUP/Architecture.txt")"
CURRENT_ARCH="$(dpkg --print-architecture)"

[[ "$SAVED_VERSION" == "1.9.99.36@25.05.1-83-gf479562b" ]] \
    || fail "Unsupported backup SVXLink version"

[[ "$SAVED_VERSION" == "$CURRENT_VERSION" ]] \
    || fail "Backup SVXLink version mismatch"

[[ "$SAVED_ARCH" == "armhf" && "$SAVED_ARCH" == "$CURRENT_ARCH" ]] \
    || fail "Backup architecture mismatch"

echo "Backup compatibility: OK"
echo

echo "=== Checking manifest ==="

declare -A SEEN
COUNT=0

while IFS=$'\t' read -r STATE FILE
do
    case "$FILE" in
        /usr/lib/arm-linux-gnueabihf/svxlink/ModuleParrot.so|\
        /etc/svxlink/svxlink.d/ModuleParrot.conf|\
        /usr/share/svxlink/events.d/local/Parrot.tcl|\
        /usr/share/svxlink/events.d/local/Parrot-AudioCheck.tcl|\
        /usr/share/svxlink/sounds/de_DE/Parrot/level_very_low.wav|\
        /usr/share/svxlink/sounds/de_DE/Parrot/level_low.wav|\
        /usr/share/svxlink/sounds/de_DE/Parrot/level_ok.wav|\
        /usr/share/svxlink/sounds/de_DE/Parrot/level_high.wav|\
        /usr/share/svxlink/sounds/de_DE/Parrot/level_very_high.wav|\
        /usr/share/svxlink/sounds/de_DE/Parrot/test_invalid.wav)
            ;;
        *)
            fail "Invalid manifest path: $FILE"
            ;;
    esac

    [[ -z "${SEEN[$FILE]:-}" ]] \
        || fail "Duplicate manifest entry: $FILE"

    SEEN["$FILE"]=1

    case "$STATE" in
        PRESENT)
            [[ -f "$BACKUP$FILE" && ! -L "$BACKUP$FILE" ]] \
                || fail "Missing or unsupported backup file: $FILE"
            echo "RESTORE: $FILE"
            ;;
        ABSENT)
            echo "REMOVE:  $FILE"
            ;;
        *)
            fail "Invalid manifest entry"
            ;;
    esac

    COUNT=$((COUNT + 1))

done < "$BACKUP/manifest.txt"

[[ "$COUNT" -eq 10 ]] || fail "Incomplete manifest"

echo
echo "Backup validation: OK"

if [[ "$MODE" == "--check" ]]; then
    echo "Check only. No system files changed."
    exit 0
fi

echo
if [[ "$MODE" != "--restore-auto" ]]; then
read -r -p "Restore this backup? Type YES: " ANSWER

[[ "$ANSWER" == "YES" ]] || fail "Rollback cancelled"
else
    echo "Automatic rollback requested by installer."
fi

# Restore the service state recorded before installation.
WAS_ACTIVE=0

if [[ -f "$BACKUP/Service-State.txt" ]]; then
    SERVICE_STATE="$(cat "$BACKUP/Service-State.txt")"

    case "$SERVICE_STATE" in
        active)
            WAS_ACTIVE=1
            ;;
        inactive)
            WAS_ACTIVE=0
            ;;
        *)
            fail "Invalid saved service state"
            ;;
    esac

    echo "Saved service state: $SERVICE_STATE"
else
    # Compatibility with older backups.
    if systemctl is-active --quiet svxlink; then
        WAS_ACTIVE=1
    fi

    echo "Legacy backup: using current service state"
fi

echo "=== Stopping SVXLink ==="
systemctl stop svxlink

echo "=== Restoring files ==="

while IFS=$'\t' read -r STATE FILE
do
    case "$STATE" in
        PRESENT)
            mkdir -p "$(dirname "$FILE")"
            cp -a --remove-destination -- "$BACKUP$FILE" "$FILE"
            cmp "$BACKUP$FILE" "$FILE"
            echo "Restored: $FILE"
            ;;
        ABSENT)
            rm -f -- "$FILE"
            echo "Removed: $FILE"
            ;;
    esac

done < "$BACKUP/manifest.txt"

if [[ "$WAS_ACTIVE" -eq 1 ]]; then
    echo "=== Starting SVXLink ==="
    systemctl start svxlink
    systemctl is-active --quiet svxlink
fi

echo
echo "Rollback successfully completed."
