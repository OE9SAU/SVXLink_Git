
SH1106 OLED Status Display (Raspberry Pi)
=================================

Zeigt Netzwerkstatus, IP-Adresse, Uhrzeit und Sys-Daten auf einem SH1106 OLED am Raspberry Pi an.
Die Installation erfolgt automatisch.

Sicherheitshinweis
------------------
Der Installer wird mit Root-Rechten ausgeführt:

curl … | sudo bash

Prüfen Sie den Inhalt vorab:
 ```
curl -fsSL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/RPI_Status_OLED/install.sh | less
 ```
Voraussetzungen
---------------
- Raspberry Pi OS (Bullseye / Bookworm)
- I²C aktiviert (raspi-config)
- SH1106 OLED (I²C, Adresse 0x3C)
- Internetverbindung

Installation (Empfohlen)
------------------------
Einfach kopieren und ausführen:
 ```
curl -fsSL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/RPI_Status_OLED/install.sh | sudo bash
 ```
Nach der Installation:
- Das Python-Programm wird installiert
- Ein systemd-Service wird eingerichtet
- Das OLED startet automatisch

USER CONFIGURATION 
---------------------
Im Script "oled_sh1106.py" können in den Zeilen 10 bis 26, USER Configurationen vorgenommen werden.
Wurden Änderungen durchgeführt muss ein Restart der Service-Datei erfolgen.
 ```
sudo systemctl restart oled-sh1106.service
 ```

Service-Status prüfen
---------------------
 ```
systemctl status oled-sh1106.service
 ```
Deinstallation (alles rückgängig machen)
----------------------------------------

1) Service stoppen und deaktivieren
 ```
sudo systemctl stop oled-sh1106.service && sudo systemctl disable oled-sh1106.service
 ```
2) Service-Datei entfernen
 ```
sudo rm -f /etc/systemd/system/oled-sh1106.service && sudo systemctl daemon-reload
 ```
3) Python-Skript löschen

Standardpfad (User pi):
 ```
sudo rm -f /home/pi/oled_sh1106.py
 ```
Optional: Python-Abhängigkeiten entfernen
-----------------------------------------
Nur ausführen, wenn diese Pakete nicht mehr benötigt werden:
 ```
sudo python3 -m pip uninstall -y luma.oled luma.core
 ```
Optional: Systempakete entfernen
--------------------------------
 ```
sudo apt remove -y python3-pip python3-pil python3-smbus i2c-tools
 ```
 ```
sudo apt autoremove -y
 ```

Dateien & Services (Übersicht)
------------------------------
Python-Skript:        /home/<user>/oled_sh1106.py

systemd-Service:     /etc/systemd/system/oled-sh1106.service

Service-Name:        oled-sh1106.service
