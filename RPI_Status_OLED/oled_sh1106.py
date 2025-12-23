#!/usr/bin/env python3
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
        res = fcntl.ioctl(s.fileno(), 0x8915, ifreq)  # SIOCGIFADDR
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


def pick_iface(preferred: Iterable[str] = ("wlan0", "eth0")) -> str:
    preferred = tuple(preferred)

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

    def fmt_bytes(n: float) -> str:
        for unit in ("B", "K", "M", "G", "T"):
            if n < 1024 or unit == "T":
                return f"{n:.0f}{unit}" if unit == "B" else f"{n:.1f}{unit}"
            n /= 1024
        return f"{n:.1f}T"

    return fmt_bytes(float(used)), fmt_bytes(float(total)), f"{pct:.0f}%"


def get_mem_usage() -> Tuple[str, str, str]:
    mem_total_kb = 0
    mem_avail_kb = 0
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    mem_total_kb = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    mem_avail_kb = int(line.split()[1])

        used_kb = max(mem_total_kb - mem_avail_kb, 0)
        pct = (used_kb / mem_total_kb) * 100 if mem_total_kb else 0.0

        def fmt_kb(kb: int) -> str:
            mb = kb / 1024
            if mb < 1024:
                return f"{mb:.0f}M"
            return f"{mb/1024:.1f}G"

        return fmt_kb(used_kb), fmt_kb(mem_total_kb), f"{pct:.0f}%"
    except OSError:
        return "?", "?", "?"


def get_load1() -> str:
    try:
        with open("/proc/loadavg", "r", encoding="utf-8") as f:
            return f.read().split()[0]
    except OSError:
        return "?"


def get_cpu_temp_c() -> Optional[float]:
    path = "/sys/class/thermal/thermal_zone0/temp"
    try:
        with open(path, "r", encoding="utf-8") as f:
            v = int(f.read().strip())
        return v / 1000.0
    except (OSError, ValueError):
        return None


def get_hostname() -> str:
    try:
        return socket.gethostname()
    except Exception:
        return "RaspberryPi"


def get_uptime_short() -> str:
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as f:
            seconds = int(float(f.read().split()[0]))
        days, rem = divmod(seconds, 86400)
        hours, rem = divmod(rem, 3600)
        mins, _ = divmod(rem, 60)
        return f"{days}d {hours:02d}:{mins:02d}" if days > 0 else f"{hours:02d}:{mins:02d}"
    except Exception:
        return "?"


def get_wlan_ssid() -> Optional[str]:
    """
    Robust (auch im systemd-Service): SSID über 'iw dev wlan0 link'
    """
    try:
        res = subprocess.run(
            ["iw", "dev", "wlan0", "link"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=0.6,
            check=False,
        )
        for line in res.stdout.splitlines():
            if "SSID:" in line:
                return line.split("SSID:", 1)[1].strip() or None
        return None
    except Exception:
        return None


def load_font(font_size: int) -> ImageFont.ImageFont:
    # gängige Pfade am Raspberry Pi OS
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, font_size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_page(device, font, lines: list[str], line_h: int) -> None:
    with canvas(device) as draw:
        y = 0
        for line in lines:
            draw.text((0, y), line, font=font, fill=255)
            y += line_h


def page1_network(title: str, iface: str, status: str, ip_text: str, ssid: Optional[str], now: str) -> list[str]:
    # 4 Zeilen, kurz halten
    l1 = title[:16] + f" {now}"
    l2 = f"{iface}:{status}"
    l3 = f"IP {ip_text}"[:21]
    l4 = f"SSID {ssid}"[:21] if (iface == "wlan0" and ssid) else "SSID -"
    return [l1, l2, l3, l4]


def page2_system(title: str, load1: str, temp_c: Optional[float], uptime: str, ram_pct: str, disk_pct: str) -> list[str]:
    t = f"{temp_c:.0f}C" if temp_c is not None else "-C"
    l1 = title[:16] + " SYS"
    l2 = f"Temp {t}  L {load1}"
    l3 = f"RAM {ram_pct}  SD {disk_pct}"
    l4 = f"Up {uptime}"
    return [l1[:21], l2[:21], l3[:21], l4[:21]]


def page3_details(title: str, ram_used: str, ram_total: str, disk_used: str, disk_total: str) -> list[str]:
    l1 = title[:16] + " DET"
    l2 = f"RAM {ram_used}/{ram_total}"
    l3 = f"SD  {disk_used}/{disk_total}"
    return [l1[:21], l2[:21], l3[:21], l4[:21]]


def main() -> None:
    I2C_PORT = 1
    I2C_ADDRESS = 0x3C
    ROTATE = 0

    REFRESH_SECONDS = 1
    PAGE_SECONDS = 5

    # Größere Schrift: 14 ist meist sehr gut auf 128x64 (4 Zeilen)
    FONT_SIZE = 14
    LINE_H = 16  # Zeilenhöhe passend zur Fontgröße (14 -> 16 ist gut)

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = load_font(FONT_SIZE)

    title = get_hostname()

    page = 0
    last_switch = time.monotonic()

    while True:
        now_mono = time.monotonic()
        if now_mono - last_switch >= PAGE_SECONDS:
            page = (page + 1) % 3
            last_switch = now_mono

        # Daten sammeln
        iface = pick_iface(("wlan0", "eth0"))
        ip = get_iface_ipv4(iface)
        is_up = bool(ip) or iface_up(iface)
        status = "UP" if is_up else "DOWN"
        ip_text = ip if ip else "no IP"
        now = datetime.now().strftime("%H:%M")

        ssid = get_wlan_ssid() if iface == "wlan0" else None

        load1 = get_load1()
        temp_c = get_cpu_temp_c()
        uptime = get_uptime_short()
        ram_used, ram_total, ram_pct = get_mem_usage()
        disk_used, disk_total, disk_pct = get_root_disk_usage()

        if page == 0:
            lines = page1_network(title, iface, status, ip_text, ssid, now)
        elif page == 1:
            lines = page2_system(title, load1, temp_c, uptime, ram_pct, disk_pct)
        else:
            lines = page3_details(title, ram_used, ram_total, disk_used, disk_total)

        draw_page(device, font, lines, LINE_H)
        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
