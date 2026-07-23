# SVXLink APRS Wetteransage Script

## 🧾 Beschreibung

Dieses Perl-Script liest die aktuelle Wetterdaten von Deiner Wetterstation auf aprs.fi aus, und erzeugt eine SVXLink-kompatible TCL-Datei, welche dann als Sprachansage für ein Relais oder sonstiges verwendet werden kann.

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
```
sudo apt update

sudo apt install perl libwww-perl libxml-simple-perl
```
---

## 📥 Installation
Script einfügen:
```
cd /opt &&
sudo nano wx_aprs_wxnatural.pl
```
Rechte anpassen:
```
sudo chmod +x /opt/wx_aprs_wxnatural.pl
```
---

## 🔧 Konfiguration

Im Script folgende Werte anpassen:

my $call   = "YOUR WX-CALL";

my $apikey = "YOUR WX-CALL_API_KEY";

APRS API-Key:
https://aprs.fi/page/api

---

## ▶️ Manuell starten
```
perl /opt/wx_aprs_wxnatural.pl
```
Erzeugt:

/tmp/wx_oe9xvi.tcl

---

## 🔊 Sprachfiles (WxNatural)

Ordner "WxNatural" nach /usr/share/svxlink/sounds/de_DE kopieren bzw. wo auch immer Eure Sprachfiles liegen

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
```
sudo chown $USER:$USER /tmp/wx_pressure_last.txt
```
---

## 🚀 Cronjob einrichten, alle 10min werden die Wetterdaten aktualisiert
```
crontab -e
```
```
2-59/10 * * * * /usr/bin/perl /opt/wx_aprs_wxnatural.pl
```
---

## Logic.tcl anpassen für Wetterdatenabrufen mit DTMF 27# 
```
Copy / Paste Logic.tcl
```
---

## 🧪 Test
```
cat /tmp/wx_oe9xvi.tcl
```
---

## 🧠 Fazit

✔ Automatische Wetteransage  
✔ Für SVXLink optimiert  
✔ Einfache Installation  

---

## 📜 Lizenz

Freie Nutzung für Amateurfunk-Projekte.
