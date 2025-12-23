#!/usr/bin/env python3
import time
import socket
import fcntl
import struct
from datetime import datetime
from typing import Optional

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106
from luma.core.render import canvas
from PIL import ImageFont


def get_iface_ipv4(ifname: str) -> Optional[str]:
    """IPv4-Adresse eines Interfaces (z.B. eth0) oder None, wenn keine gesetzt."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        ifreq = struct.pack("256s", ifname[:15].encode("utf-8"))
        res = fcntl.ioctl(s.fileno(), 0x8915, ifreq)  # SIOCGIFADDR
        return socket.inet_ntoa(res[20:24])
    except OSError:
        return None
    finally:
        s.close()


def link_up(ifname: str) -> bool:
    """Link-Status über /sys/class/net/<if>/carrier (1=up, 0=down)."""
    try:
        with open(f"/sys/class/net/{ifname}/carrier", "r", encoding="utf-8") as f:
            return f.read().strip() == "1"
    except OSError:
        return False


def main() -> None:
    IFACE = "eth0"
    I2C_PORT = 1
    I2C_ADDRESS = 0x3C
    ROTATE = 0          # 0/1/2/3 = 0/90/180/270 Grad
    REFRESH_SECONDS = 2

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = ImageFont.load_default()

    while True:
        is_up = link_up(IFACE)
        ip = get_iface_ipv4(IFACE) if is_up else None

        status = "LINK UP" if is_up else "NO LINK"
        ip_text = ip if ip else "no IP"
        now = datetime.now().strftime("%H:%M:%S")

        with canvas(device) as draw:
            draw.text((0, 0),  "Raspberry Pi", font=font, fill=255)
            draw.text((0, 14), f"{IFACE}: {status}", font=font, fill=255)
            draw.text((0, 28), f"IP: {ip_text}", font=font, fill=255)
            draw.text((0, 42), f"Time: {now}", font=font, fill=255)

        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
