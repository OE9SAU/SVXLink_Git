# 📡 SVXLink APRS Wetteransage Script

## 🧾 Beschreibung

Dieses Perl-Script ruft aktuelle Wetterdaten von **aprs.fi** ab und erzeugt eine **SVXLink-kompatible TCL-Datei**, die eine automatische Sprachansage für ein Relais oder Gateway bereitstellt.

Die Ausgabe ist für den Amateurfunk optimiert und verwendet eine klare, verständliche Sprache.

---

## 📊 Funktionen

- 🌡 Temperatur (inkl. Dezimalwerte)
- 💧 Luftfeuchtigkeit
- 📉 Luftdruck inkl. Trend (steigend / fallend / gleichbleibend)
- 🌬 Windrichtung, Geschwindigkeit und Böen
- 🌧 Niederschlag (aktuell + letzte 24 Stunden)
- 🔊 Direkte Ausgabe für SVXLink

---

## ⚙️ Voraussetzungen

System:

- Debian / Ubuntu / Raspberry Pi OS
- SVXLink installiert und funktionsfähig

Benötigte Pakete:

sudo apt update
sudo apt install perl libwww-perl libxml-simple-perl

---

## 📥 Installation

cd /opt
sudo nano wx_aprs_wxnatural.pl

Script einfügen und speichern:

sudo chmod +x /opt/wx_aprs_wxnatural.pl

---

## 🔧 Konfiguration

Im Script folgende Werte anpassen:

my $call   = "OE9XVI-6";
my $apikey = "DEIN_API_KEY";

APRS API-Key:
https://aprs.fi/page/api

---

## ▶️ Manuell starten

perl /opt/wx_aprs_wxnatural.pl

Erzeugt:

/tmp/wx_oe9xvi.tcl

---

## 📢 Einbindung in SVXLink

source /tmp/wx_oe9xvi.tcl

---

## 🔊 Sprachfiles (WxNatural)

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

---

## 📊 Logik

### 🌧 Niederschlag

- 1h → aktueller Niederschlag
- 24h → immer zusätzliche Ausgabe

### 📉 Luftdrucktrend

- +1 hPa → steigend
- -1 hPa → fallend
- sonst → gleichbleibend

### 🌬 Wind

- < 5 km/h → Windstille
- Böen nur wenn relevant

---

## 🔒 Berechtigungsproblem

sudo chown $USER:$USER /tmp/wx_pressure_last.txt

---

## 🚀 Cronjob

crontab -e

*/5 * * * * /usr/bin/perl /opt/wx_aprs_wxnatural.pl

---

## 🧪 Test

cat /tmp/wx_oe9xvi.tcl

---

## 🧠 Fazit

✔ Automatische Wetteransage  
✔ Für SVXLink optimiert  
✔ Einfache Installation  

---

## 📜 Lizenz

Freie Nutzung für Amateurfunk-Projekte.
