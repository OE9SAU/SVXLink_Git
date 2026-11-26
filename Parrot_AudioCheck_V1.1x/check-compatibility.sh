#!/bin/bash

set -euo pipefail

EXPECTED_VERSION="1.9.99.36@25.05.1-83-gf479562b"
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
echo " SVXLink Parrot AudioCheck V1.10"
echo " Compatibility Check"
echo "=========================================="
echo

command -v svxlink >/dev/null || fail "SVXLink not found"

SVXLINK_VERSION="$(timeout -k 2s 10s svxlink --version 2>&1)"
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

    # Unknown module checksums require runtime verification.

    0ea27384bd3ea0fac8bc0cdeb20c2aeafa57a8bf0adef3ed31e633a92e3bd4b5)
        echo "AudioCheck V1.10"
        ;;

    *)
        echo "WARNING: Unknown Parrot module checksum: $HASH"
        echo "WARNING: ABI compatibility has not been verified."
        echo "WARNING: Runtime verification required after installation."
        ;;

esac

echo
echo "Preliminary compatibility check: OK"
