# SVXLink Parrot AudioCheck – Versionshistorie

## V1.10 – 26.11.2026

### Neue SVXLink-Quellcode-Basis

- Eigenständige Versionsreihe V1.1x.
- Portierung auf SVXLink 1.9.99.36@25.05.1-83-gf479562b.
- Unveränderte AudioCheck-Funktionalität gegenüber V1.02.
- Neues ARMHF-Binärmodul.
- Interne Abtastrate weiterhin 16000 Hz.
- Unterstützung der neuen TCL-Modulstruktur mit Module.tcl und Mixin.
- Angepasste Kompatibilitätsprüfung.
- Separates Backup-Verzeichnis für V1.1x.
- Zusätzliche SVXLink-Versions- und Architekturprüfung beim Rollback.
- Release-Prüfsummenprüfung vor der Kompatibilitätsprüfung.

### Erfolgreich abgeschlossene Entwicklungstests

- Kompilierung des Parrot-Moduls.
- Prüfung der Compiler-Einstellungen.
- Isolierter TCL-Funktionstest aller Sprachbewertungen.
- Prüfung der WAV-Dateisuche und Audio-Pausen.
- TCL-Neuinstallation und wiederholte Installation.
- Übernahme bekannter AudioCheck-TCL-Blöcke.
- Ablehnung manuell veränderter AudioCheck-TCL-Blöcke.
- Konfigurations-Updater einschließlich Erhaltung individueller Werte.

### Entwicklungsstatus

- Experimentelle Version, noch nicht freigegeben.
- Originalmodul-Prüfsumme des Zielsystems noch ausstehend.
- Praktischer Installations- und Rollback-Test noch ausstehend.
- SVXLink-Laufzeit- und HF-Funktionstest noch ausstehend.
- Keine Binary-Kompatibilität mit der Versionsreihe V1.0x zugesichert.

---

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
