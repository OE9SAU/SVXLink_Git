#!/bin/bash

cd /var/www/html/include

rm tgdb.php

wget https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/tgdb.txt

cp /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php

chown svxlink:svxlink /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php
chmod 755 /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php 

rm tgdb.txt
