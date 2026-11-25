#!/bin/bash

set -euo pipefail

EXPECTED_VERSION="1.8.99.11@24.02-48-g9d6e0c79"
EXPECTED_ARCH="armhf"

MOD="/usr/lib/arm-linux-gnueabihf/svxlink/ModuleParrot.so"
CONF="/etc/svxlink/svxlink.d/ModuleParrot.conf"
EVENTS="/usr/share/svxlink/events.d"
SOUNDS="/usr/share/svxlink/sounds/de_DE/Parrot"

fail()
{
    echo "ERROR: $*" >&2
    exit 1
}

echo "=========================================="
echo " SVXLink Parrot AudioCheck V1.02"
echo " Compatibility Check"
echo "=========================================="
echo

command -v svxlink >/dev/null || fail "SVXLink not found"

SVXLINK_VERSION="$(svxlink --version 2>&1)"
ARCH="$(dpkg --print-architecture)"

. /etc/os-release

echo "SVXLink:      $SVXLINK_VERSION"
echo "Architecture: $ARCH"
echo "OS:           $PRETTY_NAME"
echo

[[ "$SVXLINK_VERSION" == "$EXPECTED_VERSION" ]] \
    || fail "Unsupported SVXLink version"

[[ "$ARCH" == "$EXPECTED_ARCH" ]] \
    || fail "Unsupported architecture"

[[ "${VERSION_CODENAME:-}" == "bookworm" ]] \
    || fail "Unsupported operating system"

[[ -f "$MOD" ]] || fail "Parrot module not found"
[[ -f "$CONF" ]] || fail "Parrot configuration not found"
[[ -f "$EVENTS/Parrot.tcl" ]] || fail "Parrot TCL not found"
[[ -d "$SOUNDS" ]] || fail "German sound directory not found"

echo "=== Installed Parrot module ==="

HASH="$(sha256sum "$MOD" | awk '{print $1}')"

case "$HASH" in

    7fece04577f8769f9527019b0f7aee1590e52181a93d14ab7f0afaaabf5a7faa)
        echo "Original SVXLink Parrot"
        ;;

    bc345ba8a378a78262f0acf24e9e9fb5cda420413b2f0a46326a9d38f93c6ab3)
        echo "AudioCheck V1.0"
        ;;

    d43ed9b8629cc943c1fe15d24b60d7df9079f11484e553101f9ad8f9e6896a5d)
        echo "AudioCheck V1.01"
        ;;

    2c1f6bcffeed9a5080e13718f39be7d5dd744b990aff949a019c24a2f6636bc1)
        echo "AudioCheck V1.02"
        ;;

    *)
        fail "Unknown Parrot module checksum: $HASH"
        ;;

esac

echo
echo "Compatibility check: OK"
