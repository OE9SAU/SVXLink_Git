#!/bin/bash

cd /var/www/html/include

sudo rm tgdb.php

sudo wget https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/tgdb.txt

sudo cp /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php

sudo chown svxlink:svxlink /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php
sudo chmod 755 /var/www/html/include/tgdb.txt /var/www/html/include/tgdb.php 

sudo rm tgdb.txt
