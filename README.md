# SHARI «Wifi Configurator» 

The SHARI Image includes a WLAN Configuration Page for switching between WiFi networks.You can access it in your browser at: http://YOUR-SHARI-IP/wifi.php

The original version of the code may have some permission issues. To get it working properly, run the following commands:

**Backup the original file**

sudo cp /var/www/html/wifi/index.php /var/www/html/wifi/index.php.bak && sudo cp /var/www/html/wifi.php /var/www/html/wifi.php.bak


**Download the fixed version of the file**

sudo wget -O /var/www/html/wifi/index.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi/index.php && sudo wget -O /var/www/html/wifi.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi.php



# TG_Update:

**Backup command (safely backs up old files, if they exist):**

sudo cp /var/www/html/include/tgdb_update.sh /var/www/html/include/tgdb_update.sh.bak && 
sudo cp /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.txt.bak

**Download and run the new script:**

sudo wget -O /var/www/html/include/tgdb_update.sh https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/TG_Update/tgdb_update.sh && \
sudo chmod +x /var/www/html/include/tgdb_update.sh && \
cd /var/www/html/include && \
sudo ./tgdb_update.sh


# SHARI goes APRS:

Script that sends your position data to an APRS server for your SHARI position, using ncat to transmit the data.

v1.0 only USB GPS-Mouse

v1.1 select fixed *LAT&LON* or *GPS-Mouse over USB* or *GPS-Mouse over RX-UART-GPIO*

**Howtorun:**

sudo apt install ncat

sudo nano shari_aprs.service
 ```
[Unit]
Description=startet /home/svxlink/shari_aprs.py beim Booten

After=network.target

[Service]
User=svxlink

WorkingDirectory=/home/svxlink

ExecStart=/usr/bin/python3 /home/svxlink/shari_aprs.py

Restart=on-failure

[Install]
WantedBy=multi-user.target
 ```
sudo systemctl daemon-reload

sudo systemctl restart shari_aprs.service

sudo systemctl status shari_aprs.service


