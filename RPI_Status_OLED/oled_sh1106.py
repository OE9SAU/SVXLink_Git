#!/usr/bin/env python3
import time
import socket
import fcntl
import struct
from datetime import datetime
from typing import Optional, Iterable

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106
from luma.core.render import canvas
from PIL import ImageFont


def get_iface_ipv4(ifname: str) -> Optional[str]:
    """IPv4-Adresse eines Interfaces (z.B. eth0/wlan0) oder None, wenn keine gesetzt."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        ifreq = struct.pack("256s", ifname[:15].encode("utf-8"))
        res = fcntl.ioctl(s.fileno(), 0x8915, ifreq)  # SIOCGIFADDR
        return socket.inet_ntoa(res[20:24])
    except OSError:
        return None
    finally:
        s.close()


def iface_up(ifname: str) -> bool:
    """
    Robuster als 'carrier' bei WLAN: nutzt /sys/class/net/<if>/operstate.
    'unknown' kommt bei manchen WLAN-Treibern vor, obwohl das Interface nutzbar ist.
    """
    try:
        with open(f"/sys/class/net/{ifname}/operstate", "r", encoding="utf-8") as f:
            state = f.read().strip().lower()
        return state in ("up", "dormant", "unknown")
    except OSError:
        return False


def pick_iface(preferred: Iterable[str] = ("wlan0", "eth0")) -> str:
    """
    Wählt das 'beste' Interface:
    1) bevorzugt eines mit IPv4-Adresse
    2) sonst eines mit operstate up/dormant/unknown
    3) sonst erstes aus preferred
    """
    preferred = tuple(preferred)

    # 1) beste Wahl: hat eine IP
    for ifn in preferred:
        if get_iface_ipv4(ifn):
            return ifn

    # 2) fallback: Interface ist zumindest "up"
    for ifn in preferred:
        if iface_up(ifn):
            return ifn

    return preferred[0]


def main() -> None:
    I2C_PORT = 1
    I2C_ADDRESS = 0x3C
    ROTATE = 0          # 0/1/2/3 = 0/90/180/270 Grad
    REFRESH_SECONDS = 2

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = ImageFont.load_default()

    while True:
        iface = pick_iface(("wlan0", "eth0"))

        ip = get_iface_ipv4(iface)
        is_up = bool(ip) or iface_up(iface)

        status = "LINK UP" if is_up else "NO LINK"
        ip_text = ip if ip else "no IP"
        now = datetime.now().strftime("%H:%M:%S")

        with canvas(device) as draw:
            draw.text((0, 0),  "OE9GTV - PI", font=font, fill=255)
            draw.text((0, 14), f"{iface}: {status}", font=font, fill=255)
            draw.text((0, 28), f"IP: {ip_text}", font=font, fill=255)
            draw.text((0, 42), f"Time: {now}", font=font, fill=255)

        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
