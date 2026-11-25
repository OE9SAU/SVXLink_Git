# SVXLink Parrot AudioCheck – Versionshistorie

## V1.02 – 24.11.2026

### Neuerungen

- Akustische Bewertung des Audiopegels in fünf Stufen.
- Deutsche Sprachansagen anstelle numerischer Pegelansagen.
- Sprachansage bei ungültiger oder zu kurzer Messung.
- RMS- und Peak-Messwerte weiterhin im SVXLink-Logfile.

### Installationspaket – 25.11.2026

- Automatisierter Installer mit Kompatibilitätsprüfung.
- Prüfmodus ohne Änderung der SVXLink-Systemdateien.
- Automatische Sicherung vor der Installation.
- Rollback-Funktion mit SHA256-Prüfung.
- Erhaltung bestehender AudioCheck-Konfigurationswerte.
- TCL-Update von V1.0 und V1.01.
- Vorkompiliertes ARMHF-Binärmodul.
- Quellcode und Patch zur eigenen Kompilierung.
- Deutsche Dokumentation.

## V1.01 – 24.11.2026

- Deutsche Logmeldungen.
- Kompakte Logausgabe mit einer Zeile pro Messung.
- RMS- und Peak-Werte mit zwei Nachkommastellen.
- Deutsche Bezeichnung der Audiopegelbewertung.
- Entfernung doppelter Logmeldungen.
- Unveränderte Messalgorithmen und Bewertungsgrenzen.

## V1.0 – 24.11.2026

- Erste funktionsfähige AudioCheck-Version.
- Erweiterung des SVXLink-Moduls Parrot.
- RMS- und Peak-Messung des aufgenommenen Audiosignals.
- Konfigurierbarer RMS-Zielpegel.
- Konfigurierbare RMS-Toleranz.
- Konfigurierbare Spitzenpegelgrenze.
- Konfigurierbare Mindestmessdauer.
- Fünfstufige Audiopegelbewertung.
- Numerische Sprachansage von RMS und Peak.
- Keine Veränderung des aufgenommenen Audiosignals.
- Erste Tests mit SimplexLogic und RepeaterLogic.
