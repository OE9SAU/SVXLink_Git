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
from PIL import Image, ImageFont


def icon_from_rows(rows: list[str]) -> Image.Image:
    """Erzeugt ein 1-bit Icon aus '0/1' Zeilen."""
    h = len(rows)
    w = len(rows[0])
    im = Image.new("1", (w, h), 0)
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = 1 if ch == "1" else 0
    return im


# 12×12 Icons (optisch “ruhiger” als 8×8)
ICONS = {
    "clock": icon_from_rows([
        "000011110000",
        "000100001000",
        "001000000100",
        "010000000010",
        "010001100010",
        "010000100010",
        "010000000010",
        "010000000010",
        "001000000100",
        "000100001000",
        "000011110000",
        "000000000000",
    ]),
    "ip": icon_from_rows([
        "001111111100",
        "010000000010",
        "010111101010",
        "010100101010",
        "010100101010",
        "010111101010",
        "010000000010",
        "010010010010",
        "010111111010",
        "010000000010",
        "001111111100",
        "000000000000",
    ]),
    "wifi": icon_from_rows([
        "000000000000",
        "000111111000",
        "001000000100",
        "010011110010",
        "000100001000",
        "001001100100",
        "000010000000",
        "000100100000",
        "000001000000",
        "000001000000",
        "000000000000",
        "000000000000",
    ]),
    "lan": icon_from_rows([
        "000001000000",
        "000001000000",
        "000001000000",
        "001111111100",
        "010000000010",
        "010011110010",
        "010010010010",
        "010011110010",
        "010000000010",
        "001111111100",
        "000001000000",
        "000000000000",
    ]),
    "temp": icon_from_rows([
        "000001110000",
        "000010001000",
        "000010001000",
        "000010001000",
        "000010001000",
        "000010001000",
        "000010001000",
        "000010001000",
        "000011011000",
        "000010001000",
        "000001110000",
        "000000000000",
    ]),
    "ram": icon_from_rows([
        "001111111100",
        "010000000010",
        "010111111010",
        "010100001010",
        "010101101010",
        "010101101010",
        "010100001010",
        "010111111010",
        "010000000010",
        "001111111100",
        "000101010000",
        "000000000000",
    ]),
    "sd": icon_from_rows([
        "000011111000",
        "000111111100",
        "001100000110",
        "001011110110",
        "001010010110",
        "001011110110",
        "001100000110",
        "001100000110",
        "001111111110",
        "000111111100",
        "000011111000",
        "000000000000",
    ]),
}


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
    used, total = du.used, du.total
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


def get_wlan_ssid() -> Optional[str]:
    try:
        res = subprocess.run(
            ["iwgetid", "-r"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=0.5,
            check=False,
        )
        ssid = res.stdout.strip()
        return ssid or None
    except Exception:
        return None


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


def draw_lines(device, font, lines_with_icons) -> None:
    """
    lines_with_icons: list[tuple[icon_key_or_None, text]]
    12×12 Icon + Abstand => Text ab x=14.
    """
    with canvas(device) as draw:
        y = 0
        for icon_key, text in lines_with_icons[:6]:
            x = 0
            if icon_key:
                draw.bitmap((0, y), ICONS[icon_key], fill=255)
                x = 14
            draw.text((x, y + 1), text[:20], font=font, fill=255)  # +1 für bessere Baseline
            y += 10


def page_network(title: str, iface: str, status: str, ip_text: str, now: str, ssid: Optional[str]):
    net_icon = "wifi" if iface == "wlan0" else "lan"
    return [
        (None,  title),
        (net_icon, f"{iface}:{status}  {now}"),
        ("ip",  f"{ip_text}"),
        ("wifi", f"{ssid}" if ssid else "SSID -"),
        (None,  ""),
        (None,  "Page 1/2"),
    ]


def page_system(title: str, load1: str, temp_c: Optional[float], ram_pct: str, disk_pct: str,
                ram_used: str, ram_total: str, disk_used: str, disk_total: str, uptime: str):
    t = f"{temp_c:.0f}C" if temp_c is not None else "-C"
    return [
        (None,   title),
        ("temp", f"Temp {t}  Load {load1}"),
        ("ram",  f"RAM {ram_pct}  {ram_used}/{ram_total}"),
        ("sd",   f"SD  {disk_pct}  {disk_used}/{disk_total}"),
        ("clock", f"Up  {uptime}"),
        (None,   "Page 2/2"),
    ]


def main() -> None:
    I2C_PORT = 1
    I2C_ADDRESS = 0x3C
    ROTATE = 0

    REFRESH_SECONDS = 1   # Messwerte/Refresh
    PAGE_SECONDS = 5      # Seitenwechsel

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = ImageFont.load_default()

    title = get_hostname()[:21]

    page = 0
    last_switch = time.monotonic()

    while True:
        now_mono = time.monotonic()
        if now_mono - last_switch >= PAGE_SECONDS:
            page = (page + 1) % 2
            last_switch = now_mono

        iface = pick_iface(("wlan0", "eth0"))
        ip = get_iface_ipv4(iface)
        is_up = bool(ip) or iface_up(iface)

        status = "UP" if is_up else "DOWN"
        ip_text = ip if ip else "no IP"
        now = datetime.now().strftime("%H:%M:%S")
        ssid = get_wlan_ssid() if iface == "wlan0" else None

        load1 = get_load1()
        temp_c = get_cpu_temp_c()
        ram_used, ram_total, ram_pct = get_mem_usage()
        disk_used, disk_total, disk_pct = get_root_disk_usage()
        uptime = get_uptime_short()

        lines = page_network(title, iface, status, ip_text, now, ssid) if page == 0 else \
                page_system(title, load1, temp_c, ram_pct, disk_pct, ram_used, ram_total, disk_used, disk_total, uptime)

        draw_lines(device, font, lines)
        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
