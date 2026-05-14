# 📡 SVXLink APRS Wetteransage Script
perl /opt/wx_aprs_wxnatural.pl

Das Script erzeugt:

/tmp/wx_oe9xvi.tcl
📢 Einbindung in SVXLink

Die erzeugte Datei in SVXLink einbinden:

source /tmp/wx_oe9xvi.tcl

z.B. in einem Event oder Modul.

🔊 Sprachfiles (WxNatural)

Folgende Sprachbausteine werden benötigt:

Aktuelle_Wetterdaten_von
Stand
Die_Temperatur_betraegt
bei_einer_Luftfeuchte_von
Der_Luftdruck_betraegt
und_ist_steigend
und_ist_fallend
und_ist_gleichbleibend
Der_Wind_kommt_aus
und_weht_mit
Es_herrscht_Windstille
In_Boen_bis_zu
Aktuell_kein_Niederschlag
Niederschlag_in_der_letzten_Stunde
Niederschlag_letzten_24h
Ende_der_Wetterdurchsage
📊 Logik
🌧 Niederschlag
Aktueller Niederschlag (1h) wird separat angesagt
Niederschlag der letzten 24 Stunden wird immer zusätzlich ausgegeben

Beispiel:

Aktuell kein Niederschlag.
Niederschlag letzten 24 Stunden 0 Komma 5 Millimeter.
📉 Luftdrucktrend
+1 hPa oder mehr → steigend
-1 hPa oder mehr → fallend
sonst → gleichbleibend
🌬 Wind
< 5 km/h → Windstille
Böen werden nur angesagt, wenn relevant
🔒 Berechtigungsproblem beheben

Falls folgende Meldung erscheint:

Permission denied: /tmp/wx_pressure_last.txt

Fix:

sudo chown $USER:$USER /tmp/wx_pressure_last.txt
🚀 Automatisierung (Cronjob)

Script regelmäßig ausführen lassen:

crontab -e

Beispiel: alle 5 Minuten

*/5 * * * * /usr/bin/perl /opt/wx_aprs_wxnatural.pl
🧪 Test

Erzeugte Datei prüfen:

cat /tmp/wx_oe9xvi.tcl
💡 Hinweise
SVXLink spricht Dezimalzahlen automatisch („Komma“)
Keine Rundung bei Regenwerten notwendig
Script ist für Dauerbetrieb ausgelegt
🧠 Fazit
✔ Einfache Integration in SVXLink
✔ Automatische Wetteransagen
✔ Optimiert für Relaisbetrieb
✔ Saubere und verständliche Sprache