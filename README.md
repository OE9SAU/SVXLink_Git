# SHARI–WLAN Config:

The SHARI Image includes a WLAN Configuration Page for easy switching between WiFi networks.You can access it in your browser at: http://YOUR-IP/wifi.php

The original version of the code may have some permission issues. To get it working properly, run the following commands:

**Backup the original file**

sudo cp /var/www/html/wifi/index.php /var/www/html/shari_dashboard/wifi/index.php.bak && sudo cp /var/www/html/wifi.php /var/www/html/shari_dashboard/wifi.php.bak


**Download the fixed version of the file**

sudo wget -O /var/www/html/wifi/index.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi/index.php && sudo wget -O /var/www/html/wifi.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi.php



# TG_Update:

Replace or copy the "tgdb_update.sh" into your "/var/www/html/include" directory and startup the script with "./tgdb_update.sh".
The script will overwrites the old TG-list and add all selectable and monitorable talkgroups for SVXLink Austria.


In case of error there are some permission problems, use:

sudo chmod +x tgdb_update.sh && sudo ./tgdb_update.sh


# Shari_goes_aprs:

Script that sends your position data to an APRS server for your SHARI position, using ncat to transmit the data.

sudo apt install ncat

v1.0 only USB GPS-Mouse

v1.1 select fixed *LAT&LON* or *GPS-Mouse over USB* or *GPS-Mouse over RX-UART-GPIO*
