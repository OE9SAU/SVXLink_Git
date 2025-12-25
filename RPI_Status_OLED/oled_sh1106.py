#!/usr/bin/env python3

# ==================================================
# USER CONFIGURATION (HIER EINSTELLEN)
# ==================================================

# Anzeigename:
#   None  -> Hostname verwenden
#   "..." -> eigener Name
DISPLAY_NAME = None           # z.B. "SVXLink AT"

# Schrift / Layout
FONT_SIZE = 12                # empfohlen: 11–12 für 128x64
LINE_H = 14                   # Zeilenhöhe (FONT_SIZE + 2 ist gut)

# Seiten / Aktualisierung
REFRESH_SECONDS = 1
PAGE_SECONDS = 5

# I2C / Display
I2C_PORT = 1
I2C_ADDRESS = 0x3C
ROTATE = 0

# Netzwerk-Interfaces in Priorität
PREFERRED_IFACES = ("wlan0", "eth0")

# ==================================================
# AB HIER KEINE ÄNDERUNGEN MEHR !!
# ==================================================

import time
import socket
import fcntl
import struct
import shutil
import subprocess
from datetime import datetime
from typing import Optional, Iterable, Tuple

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106
from luma.core.render import canvas
from PIL import ImageFont


def get_iface_ipv4(ifname: str) -> Optional[str]:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        ifreq = struct.pack("256s", ifname[:15].encode("utf-8"))
        res = fcntl.ioctl(s.fileno(), 0x8915, ifreq)
        return socket.inet_ntoa(res[20:24])
    except OSError:
        return None
    finally:
        s.close()


def iface_up(ifname: str) -> bool:
    try:
        with open(f"/sys/class/net/{ifname}/operstate", "r", encoding="utf-8") as f:
            state = f.read().strip().lower()
        return state in ("up", "dormant", "unknown")
    except OSError:
        return False


def pick_iface(preferred: Iterable[str]) -> str:
    for ifn in preferred:
        if get_iface_ipv4(ifn):
            return ifn
    for ifn in preferred:
        if iface_up(ifn):
            return ifn
    return preferred[0]


def get_root_disk_usage() -> Tuple[str, str, str]:
    du = shutil.disk_usage("/")
    used = du.used
    total = du.total
    pct = (used / total) * 100 if total else 0.0

    def fmt(n: float) -> str:
        for u in ("B", "K", "M", "G", "T"):
            if n < 1024 or u == "T":
                return f"{n:.0f}{u}" if u == "B" else f"{n:.1f}{u}"
            n /= 1024
        return f"{n:.1f}T"

    return fmt(float(used)), fmt(float(total)), f"{pct:.0f}%"


def get_mem_usage() -> Tuple[str, str, str]:
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            info = {l.split(":")[0]: int(l.split()[1]) for l in f}

        used = info["MemTotal"] - info["MemAvailable"]
        pct = (used / info["MemTotal"]) * 100

        def fmt(kb: int) -> str:
            mb = kb / 1024
            return f"{mb:.0f}M" if mb < 1024 else f"{mb/1024:.1f}G"

        return fmt(used), fmt(info["MemTotal"]), f"{pct:.0f}%"
    except Exception:
        return "?", "?", "?"


def get_load1() -> str:
    try:
        with open("/proc/loadavg", "r", encoding="utf-8") as f:
            return f.read().split()[0]
    except OSError:
        return "?"


def get_cpu_temp_c() -> Optional[float]:
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r", encoding="utf-8") as f:
            return int(f.read()) / 1000.0
    except Exception:
        return None


def get_hostname() -> str:
    return socket.gethostname()


def get_uptime_short() -> str:
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as f:
            s = int(float(f.read().split()[0]))
        d, r = divmod(s, 86400)
        h, r = divmod(r, 3600)
        m, _ = divmod(r, 60)
        return f"{d}d {h:02d}:{m:02d}" if d else f"{h:02d}:{m:02d}"
    except Exception:
        return "?"


def get_wlan_ssid() -> Optional[str]:
    try:
        res = subprocess.run(
            ["iw", "dev", "wlan0", "link"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=0.5,
        )
        for line in res.stdout.splitlines():
            if "SSID:" in line:
                return line.split("SSID:", 1)[1].strip()
    except Exception:
        pass
    return None


def load_font(size: int) -> ImageFont.ImageFont:
    for p in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_page(device, font, lines, line_h):
    with canvas(device) as draw:
        y = 0
        for l in lines:
            draw.text((0, y), l, font=font, fill=255)
            y += line_h


def page1(title, iface, status, ip, ssid, now):
    return [
        f"{title[:16]} {now}",
        f"{iface}:{status}",
        f"IP {ip}"[:21],
        f"SSID {ssid}"[:21] if ssid else "SSID -",
    ]


def page2(title, load1, temp, uptime, ram_pct, disk_pct):
    t = f"{temp:.0f}C" if temp else "-C"
    return [
        title[:21],
        f"Temp {t}  L {load1}"[:21],
        f"RAM {ram_pct}  SD {disk_pct}"[:21],
        f"Up {uptime}"[:21],
    ]


def page3(title, ram_u, ram_t, disk_u, disk_t):
    return [
        title[:21],
        f"RAM {ram_u}/{ram_t}"[:21],
        f"SD  {disk_u}/{disk_t}"[:21],
        "",
    ]


def main():
    font_size = max(8, int(FONT_SIZE))
    line_h = max(font_size + 2, int(LINE_H))

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = load_font(font_size)

    title = DISPLAY_NAME if DISPLAY_NAME else get_hostname()

    page = 0
    last = time.monotonic()

    while True:
        if time.monotonic() - last >= PAGE_SECONDS:
            page = (page + 1) % 3
            last = time.monotonic()

        iface = pick_iface(PREFERRED_IFACES)
        ip = get_iface_ipv4(iface) or "no IP"
        status = "UP" if iface_up(iface) else "DOWN"
        ssid = get_wlan_ssid() if iface == "wlan0" else None

        load1 = get_load1()
        temp = get_cpu_temp_c()
        uptime = get_uptime_short()
        ram_u, ram_t, ram_p = get_mem_usage()
        disk_u, disk_t, disk_p = get_root_disk_usage()
        now = datetime.now().strftime("%H:%M")

        if page == 0:
            lines = page1(title, iface, status, ip, ssid, now)
        elif page == 1:
            lines = page2(title, load1, temp, uptime, ram_p, disk_p)
        else:
            lines = page3(title, ram_u, ram_t, disk_u, disk_t)

        draw_page(device, font, lines, line_h)
        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
