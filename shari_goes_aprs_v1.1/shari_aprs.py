# shari_aprs.py
# Autor: OE9SAU
# Beschreibung: GPS-Daten werden per APRS-IS gesendet über ncat
# Version: 1.1

import serial
import time
import subprocess
import configparser

# Konfigurationsdatei einlesen
config = configparser.ConfigParser()
config.read('shari_aprs.conf')

# APRS-Konfiguration
user = config['APRS']['MYCALL']
password = config['APRS']['PASSCODE']
server = config['APRS']['SERVER']
port = int(config['APRS']['PORT'])
senduser = user
table = config['APRS']['SYMBOL_TABLE']
symbol = config['APRS']['SYMBOL']
comment = config['APRS']['COMMENT']

# GPS-Konfiguration
gps_source = config['GPS']['gps_source'].lower()  # Quelle für GPS (usb, gpio, config)
gps_device = config['GPS'].get('DEVICE', '/dev/ttyACM0')  # Standard für USB, falls nicht gesetzt
gps_baudrate = int(config['GPS'].get('BAUDRATE', 9600))
gps_timeout = int(config['GPS'].get('TIMEOUT', 10))
print(f"GPS-Quelle: '{gps_source}'")

# Beacon-Konfiguration
send_interval = int(config['BEACON']['SEND_INTERVAL'])
send_on_move_only = config['BEACON'].getboolean('SEND_ON_MOVE_ONLY')

def convert_to_decimal(degree_min, direction):
    degrees = int(degree_min) // 100
    minutes = degree_min - degrees * 100
    decimal = degrees + minutes / 60
    if direction in ['S', 'W']:
        decimal *= -1
    return decimal

def read_gps_data():
    if gps_source == 'config':
        try:
            latitude = float(config['GPS']['LATITUDE'])
            longitude = float(config['GPS']['LONGITUDE'])
            altitude = 0.0  # Optional: Standardhöhe
            speed_kmh = 0.0  # Optional: Standardgeschwindigkeit
            print("GPS-Daten aus der Konfiguration verwendet.")
            return latitude, longitude, altitude, speed_kmh
        except KeyError:
            print("Fehler: LATITUDE oder LONGITUDE fehlen in der Konfigurationsdatei.")
            return None, None, None, None

    if gps_source == 'usb' or gps_source == 'gpio':
        ser = serial.Serial(gps_device, baudrate=gps_baudrate, timeout=gps_timeout)
        latitude = longitude = altitude = speed_kmh = None
        start_time = time.time()

        while time.time() - start_time < gps_timeout:
            line = ser.readline().decode('ascii', errors='replace').strip()

            if line.startswith('$GPGGA') or line.startswith('$GNGGA'):
                parts = line.split(',')
                try:
                    if parts[2] and parts[4]:
                        latitude = convert_to_decimal(float(parts[2]), parts[3])
                        longitude = convert_to_decimal(float(parts[4]), parts[5])
                    if parts[9]:
                        altitude = float(parts[9])
                except (ValueError, IndexError):
                    continue

            elif line.startswith('$GPRMC') or line.startswith('$GNRMC'):
                parts = line.split(',')
                try:
                    if parts[3] and parts[5]:
                        latitude = convert_to_decimal(float(parts[3]), parts[4])
                        longitude = convert_to_decimal(float(parts[5]), parts[6])
                    if parts[7]:
                        speed_knots = float(parts[7])
                        speed_kmh = speed_knots * 1.852
                except (ValueError, IndexError):
                    continue

            if latitude and longitude and altitude is not None and speed_kmh is not None:
                ser.close()
                return latitude, longitude, altitude, speed_kmh

        ser.close()
        return None, None, None, None

    print("Fehler: Ungültige GPS-Quelle.")
    return None, None, None, None

def send_aprs_data(lat, lon, alt, speed):
    aprsauth = f"user {user} pass {password}"
    data = f"{senduser}>APN100,TCPIP*:={lat}{table}{lon}{symbol}{comment}:Alt:{alt:.2f}m Speed:{speed:.2f}km/h"

    try:
        process = subprocess.run(
            ['ncat', '--send-only', server, str(port)],
            input=f"{aprsauth}\n{data}\n",
            text=True,
            capture_output=True,
            check=True
        )
        print(f"APRS-Daten erfolgreich gesendet: {data}")
    except subprocess.CalledProcessError as e:
        print(f"Fehler beim Senden der APRS-Daten: {e}")
        print(f"Fehlerdetails: {e.stderr}")

# Hauptschleife
last_lat, last_lon = None, None

while True:
    lat, lon, alt, speed = read_gps_data()

    if lat is not None:
        lat_ddmm = f"{int(abs(lat)):02d}{(abs(lat) % 1) * 60:05.2f}{'N' if lat >= 0 else 'S'}"
        lon_ddmm = f"{int(abs(lon)):03d}{(abs(lon) % 1) * 60:05.2f}{'E' if lon >= 0 else 'W'}"

        if not send_on_move_only or lat != last_lat or lon != last_lon:
            send_aprs_data(lat_ddmm, lon_ddmm, alt, speed)
            last_lat, last_lon = lat, lon

            print(f"\n--- Neue Messung ---")
            print(f"Latitude   : {lat_ddmm}")
            print(f"Longitude  : {lon_ddmm}")
            print(f"Altitude   : {alt:.2f} m")
            print(f"Speed      : {speed:.2f} km/h")
        else:
            print("Keine Änderung der GPS-Daten (Lat/Lon), keine Daten gesendet.")
    else:
        print("\nKeine gültigen GPS-Daten empfangen.")

    time.sleep(send_interval)
