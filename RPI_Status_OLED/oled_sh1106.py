#!/usr/bin/env python3
import time
import socket
import fcntl
import struct
import shutil
import os
import subprocess
from datetime import datetime
<<<<<<< HEAD
from typing import Optional
=======
from typing import Optional, Iterable, Tuple
>>>>>>> c0d7ee925a1054313af9a59d0bb3084f6c543362

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


<<<<<<< HEAD
=======
def pick_iface(preferred: Iterable[str] = ("wlan0", "eth0")) -> str:
    """
    Wählt das 'beste' Interface:
    1) bevorzugt eines mit IPv4-Adresse
    2) sonst eines mit operstate up/dormant/unknown
    3) sonst erstes aus preferred
    """
    preferred = tuple(preferred)

    for ifn in preferred:
        if get_iface_ipv4(ifn):
            return ifn

    for ifn in preferred:
        if iface_up(ifn):
            return ifn

    return preferred[0]


def get_root_disk_usage() -> Tuple[str, str, str]:
    """
    SD/Root-FS Nutzung via shutil.disk_usage('/').
    Rückgabe: (used_str, total_str, percent_str)
    """
    du = shutil.disk_usage("/")
    used = du.used
    total = du.total
    pct = (used / total) * 100 if total else 0.0

    def fmt_bytes(n: int) -> str:
        # kompakt in GiB/MiB
        for unit in ("B", "K", "M", "G", "T"):
            if n < 1024 or unit == "T":
                return f"{n:.0f}{unit}" if unit == "B" else f"{n:.1f}{unit}"
            n /= 1024
        return f"{n:.1f}T"

    return fmt_bytes(used), fmt_bytes(total), f"{pct:.0f}%"


def get_mem_usage() -> Tuple[str, str, str]:
    """
    RAM Nutzung aus /proc/meminfo.
    Rückgabe: (used_str, total_str, percent_str)
    """
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
    """1-min Load Average (kompakt)."""
    try:
        with open("/proc/loadavg", "r", encoding="utf-8") as f:
            return f.read().split()[0]
    except OSError:
        return "?"


def get_cpu_temp_c() -> Optional[float]:
    """CPU Temperatur (Raspberry Pi) in °C oder None."""
    path = "/sys/class/thermal/thermal_zone0/temp"
    try:
        with open(path, "r", encoding="utf-8") as f:
            v = int(f.read().strip())
        return v / 1000.0
    except OSError:
        return None
    except ValueError:
        return None


def get_hostname() -> str:
    try:
        return socket.gethostname()
    except Exception:
        return "RaspberryPi"


def get_wlan_ssid() -> Optional[str]:
    """
    Optional: SSID via iwgetid (wenn installiert).
    Gibt None zurück, wenn nicht verfügbar/kein WLAN.
    """
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


>>>>>>> c0d7ee925a1054313af9a59d0bb3084f6c543362
def main() -> None:
    IFACE = "eth0"
    I2C_PORT = 1
    I2C_ADDRESS = 0x3C
    ROTATE = 0          # 0/1/2/3 = 0/90/180/270 Grad
    REFRESH_SECONDS = 2

    # Anzeige-Optionen
    SHOW_SSID = True
    SHOW_DISK = True
    SHOW_RAM = True
    SHOW_LOAD = True
    SHOW_TEMP = True

    serial = i2c(port=I2C_PORT, address=I2C_ADDRESS)
    device = sh1106(serial, rotate=ROTATE)
    font = ImageFont.load_default()

    title = get_hostname()

    while True:
<<<<<<< HEAD
        is_up = link_up(IFACE)
        ip = get_iface_ipv4(IFACE) if is_up else None
=======
        iface = pick_iface(("wlan0", "eth0"))
        ip = get_iface_ipv4(iface)
        is_up = bool(ip) or iface_up(iface)
>>>>>>> c0d7ee925a1054313af9a59d0bb3084f6c543362

        status = "UP" if is_up else "DOWN"
        ip_text = ip if ip else "no IP"
        now = datetime.now().strftime("%H:%M:%S")

        # Sammeln der zusätzlichen Parameter (kompakt)
        ssid = get_wlan_ssid() if (SHOW_SSID and iface == "wlan0") else None
        disk_used, disk_total, disk_pct = get_root_disk_usage() if SHOW_DISK else ("", "", "")
        ram_used, ram_total, ram_pct = get_mem_usage() if SHOW_RAM else ("", "", "")
        load1 = get_load1() if SHOW_LOAD else ""
        temp_c = get_cpu_temp_c() if SHOW_TEMP else None

        # 128x64 mit default font: y-Schritte ~10-12 px; hier 6 Zeilen à 10 px + bisschen Luft
        lines = []
        lines.append(title[:16])  # etwas kürzen, falls Hostname lang
        lines.append(f"{iface}:{status}  {now}")
        lines.append(f"IP {ip_text}"[:21])  # Zeile begrenzen

        # Eine "Statuszeile" für Systemwerte
        sys_parts = []
        if SHOW_LOAD:
            sys_parts.append(f"L{load1}")
        if SHOW_TEMP and temp_c is not None:
            sys_parts.append(f"T{temp_c:.0f}C")
        if SHOW_RAM:
            sys_parts.append(f"R{ram_pct}")
        if SHOW_DISK:
            sys_parts.append(f"D{disk_pct}")
        if sys_parts:
            lines.append(" ".join(sys_parts)[:21])

        # Optional SSID oder (als Alternative) RAM/Disk Details
        if ssid:
            lines.append(f"SSID {ssid}"[:21])
        else:
            # Detailzeile: RAM oder Disk (je nachdem was aktiv ist)
            detail = []
            if SHOW_RAM:
                detail.append(f"RAM {ram_used}/{ram_total}")
            if SHOW_DISK:
                detail.append(f"SD {disk_used}/{disk_total}")
            if detail:
                lines.append("  ".join(detail)[:21])

        # Fallback, falls weniger als 6 Zeilen erzeugt wurden
        while len(lines) < 6:
            lines.append("")

        with canvas(device) as draw:
<<<<<<< HEAD
            draw.text((0, 0),  "Raspberry Pi", font=font, fill=255)
            draw.text((0, 14), f"{IFACE}: {status}", font=font, fill=255)
            draw.text((0, 28), f"IP: {ip_text}", font=font, fill=255)
            draw.text((0, 42), f"Time: {now}", font=font, fill=255)
=======
            y = 0
            for line in lines[:6]:
                draw.text((0, y), line, font=font, fill=255)
                y += 10
>>>>>>> c0d7ee925a1054313af9a59d0bb3084f6c543362

        time.sleep(REFRESH_SECONDS)


if __name__ == "__main__":
    main()
