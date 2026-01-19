# Systemupdate für Rasberry mit SVXLink bzw. SAULINK

Führt ein normales Systemupdate (apt update + apt upgrade) durch und stellt anschließend sicher, 

dass Apache wieder mit PrivateTmp=false läuft. Was für die Funktion von DTMF und Co benötigt wird!

https://github.com/OE9SAU/SAULink9/tree/main/Scripts

# TG_Update:

**Backup command (safely backs up old files, if they exist):**
 ```
sudo cp /var/www/html/include/tgdb_update.sh /var/www/html/include/tgdb_update.sh_back
 ```
**Download and run the new script:**
 ```
sudo wget -O /var/www/html/include/tgdb_update.sh https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/TG_Update/tgdb_update.sh && \
sudo chmod +x /var/www/html/include/tgdb_update.sh && \
cd /var/www/html/include && \
sudo ./tgdb_update.sh
 ```

# SVXLink Remote Display
with ESP and LCD, see documentation [here](svxlink_remote_display/Svxlink_Remote_Display.pdf)

with M5Stack, see documentation [here](M5stack_svxlink_remote_display), please contact DL5RD for further details 


# SHARI «Wifi Configurator» 

The SHARI Image includes a WLAN Configuration Page for switching between WiFi networks.You can access it in your browser at: http://YOUR-SHARI-IP/wifi.php

The original version of the code may have some permission issues. To get it working properly, run the following commands:

**Backup the original file**
 ```
sudo cp /var/www/html/wifi/index.php /var/www/html/wifi/index.php_back && sudo cp /var/www/html/wifi.php /var/www/html/wifi.php_back
 ```

**Download the fixed version of the file**
 ```
sudo wget -O /var/www/html/wifi/index.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi/index.php && sudo wget -O /var/www/html/wifi.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi.php
 ```

# SHARI goes APRS:

Script that sends your position data to an APRS server for your SHARI position, using ncat to transmit the data.

v1.0 only USB GPS-Mouse

*v2.0 select fixed *LAT&LON* or *GPS-Mouse over USB* or *GPS-Mouse over RX-UART-GPIO*, without timestamp*

v2.1 select fixed *LAT&LON* or *GPS-Mouse over USB* or *GPS-Mouse over RX-UART-GPIO*, with timestamp

**!Your need to install ncat: sudo apt install ncat**

**HowtoAUTOrun:**

sudo nano shari_aprs.service
 ```
[Unit]
Description=startet shari_aprs_vx.x.py beim booten

After=network.target

[Service]
User=svxlink

WorkingDirectory=/home/svxlink

ExecStart=/usr/bin/python3 /home/svxlink/shari_aprs_v2.1.py

Restart=on-failure

[Install]
WantedBy=multi-user.target
 ```
sudo systemctl daemon-reload

sudo systemctl enable shari_aprs.service

sudo systemctl restart shari_aprs.service

sudo systemctl status shari_aprs.service

# Rpi OLED Status Display

Sicherheitshinweis, der Installer wird mit Root-Rechten ausgeführt, mehr Infos im README

https://github.com/OE9SAU/SVXLink_Git/blob/main/RPI_Status_OLED/README.md

```
curl -fsSL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/main/RPI_Status_OLED/install.sh | sudo bash
```
Das OLED zeigt anschliessend den Netzwerkstatus, IP-Adresse, Uhrzeit und System-Daten an



