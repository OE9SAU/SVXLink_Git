**SHARI WLAN:**

Current SHARI Image including a WLAN Config Page. Usefull for changing WLAN locations: http://YOUR-IP/wifi.php
The orignal code has some right issues. To get the code running use:

sudo cp /var/www/html/shari_dashboard/wifi/index.php /var/www/html/shari_dashboard/wifi/index.php.bak

sudo wget -O /var/www/html/shari_dashboard/wifi/index.php https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/shari_dashboard/wifi/index.php




**TG_Update:**

Replace or copy the "tgdb_update.sh" into your "/var/www/html/include" directory and startup the script with "./tgdb_update.sh".
The script will overwrites the old TG-list and add all selectable and monitorable talkgroups for SVXLink Austria.


In case of error there are some permission problems, use:

sudo chmod +x tgdb_update.sh && sudo ./tgdb_update.sh



**shari_goes_aprs:**

Script that sends your position data to an APRS server for your SHARI position, using ncat to transmit the data.

sudo apt install ncat

v1.0 only USB GPS-Mouse

v1.1 select fixed *LAT&LON* or *GPS-Mouse over USB* or *GPS-Mouse over RX-UART-GPIO*
