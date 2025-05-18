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
