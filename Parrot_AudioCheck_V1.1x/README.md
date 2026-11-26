# SVXLink Parrot AudioCheck V1.10

## Entwicklungsstatus

**Experimentelle Version – noch nicht freigegeben.**

Die Versionsreihe V1.1x ist nicht binärkompatibel mit V1.0x.
Der praktische Installationstest auf dem Zielsystem steht noch aus.


## Beschreibung

AudioCheck erweitert das bestehende SVXLink-Modul Parrot
um eine automatische Audiopegelmessung.

Nach der Wiedergabe der aufgenommenen Sprache erfolgt
eine akustische Bewertung des Audiopegels.

Die Messung erfolgt lokal auf dem Hotspot oder Relais.
Eine Reflector- oder Internetverbindung ist für die
Messung nicht erforderlich.

## Funktionen

- RMS- und Peak-Messung in dBFS
- Einstellbarer RMS-Zielpegel
- Einstellbare RMS-Toleranz
- Einstellbare Spitzenpegelgrenze
- Einstellbare Mindestmessdauer
- Fünf akustische Bewertungsstufen
- Sprachansage bei ungültiger Messung
- Messwerte im SVXLink-Logfile
- Unveränderte Wiedergabe der aufgenommenen Sprache
- Automatisches Backup vor der Installation
- Rollback-Funktion
- Übernahme bekannter AudioCheck-TCL-Erweiterungen
- Erhaltung bestehender AudioCheck-Konfigurationswerte

## Download

```bash
clear
git clone https://github.com/OE9SAU/SVXLink_Git.git
cd SVXLink_Git/Parrot_AudioCheck_V1.1x
```

## Kompatibilität prüfen

Das mitgelieferte Binärmodul ist vorgesehen für:

- Raspberry Pi OS / Raspbian 12 Bookworm
- Architektur: armhf (32 Bit)
- SVXLink: 1.9.99.36@25.05.1-83-gf479562b
- Interne SVXLink-Abtastrate: 16000 Hz
- libsigc++ 2 mit kompatibler ABI
- Deutsche SVXLink-Sprachdateien

Andere SVXLink-Versionen und Architekturen werden
vom Installer nicht unterstützt.

Die SHA256-Prüfsumme des Originalmoduls wurde noch nicht verifiziert.
Unbekannte Originalmodule werden vom Installer abgelehnt.

```bash
clear

sudo ./check-compatibility.sh
```

## Installation

Lokales Entwicklungspaket öffnen:

```bash
clear
cd "$HOME/Parrot_AudioCheck_V1.10"
```

Kompatibilität prüfen:

```bash
clear
sudo ./install.sh --check
```

Installation erst nach Freigabe für das Zielsystem starten:

```bash
clear
sudo ./install.sh --install
```

Die Installation muss mit YES bestätigt werden.

Vor der Installation wird automatisch ein Backup erstellt.
SVXLink wird während der Installation kurzzeitig gestoppt.

Bestehende AudioCheck-Konfigurationswerte bleiben erhalten.

## Bedienung

Bei der Standard-Modul-ID 1:

1. Parrot mit DTMF 1# aktivieren.
2. Einige Sekunden sprechen.
3. PTT loslassen.
4. Sprachwiedergabe und Bewertung abwarten.
5. Parrot mit # deaktivieren.

## Audiopegelbewertung

Bei einem RMS-Zielpegel von -20 dBFS und einer
Toleranz von +/-2 dB gelten folgende Bewertungsstufen:

| RMS-Pegel | Sprachbewertung |
|-----------|-----------------|
| Unter -29 dBFS | Deutlich zu leise |
| -29 bis unter -22 dBFS | Etwas zu leise |
| -22 bis -18 dBFS | Optimal |
| Über -18 bis -15 dBFS | Etwas zu laut |
| Über -15 dBFS | Deutlich zu laut |

Die Grenzwerte sind Empfehlungen für dieses AudioCheck-System
und keine allgemeingültige Funknorm.

## Konfiguration

Datei: `/etc/svxlink/svxlink.d/ModuleParrot.conf`

```ini
AUDIOCHECK=1
AUDIOCHECK_TARGET_RMS=-20
AUDIOCHECK_TOLERANCE=2
AUDIOCHECK_PEAK_LIMIT=-6
AUDIOCHECK_MIN_DURATION=2000
```

| Parameter | Funktion |
|-----------|----------|
| AUDIOCHECK | 1 = aktiviert, 0 = deaktiviert |
| AUDIOCHECK_TARGET_RMS | RMS-Zielpegel in dBFS |
| AUDIOCHECK_TOLERANCE | RMS-Toleranz in dB |
| AUDIOCHECK_PEAK_LIMIT | Interne Spitzenpegelgrenze in dBFS |
| AUDIOCHECK_MIN_DURATION | Mindestmessdauer in Millisekunden |

Die Spitzenpegelgrenze beeinflusst nicht die
fünfstufige RMS-Sprachbewertung.

Empfohlene Parrot-Einstellungen:

```ini
MUTE_LOGIC_LINKING=1
FIFO_LEN=60
REPEAT_DELAY=1000
```

MUTE_LOGIC_LINKING=1 unterbindet im normalen aktiven
Parrot-Betrieb die Weiterleitung über Logic-Verbindungen.

Nach einer Konfigurationsänderung:

```bash
clear
sudo systemctl restart svxlink
```

## Logfile

Beispiel für das erwartete Logformat:

```text
Parrot: AudioCheck V1.10: RMS=-21.80 dBFS, Peak=-4.17 dBFS, Bewertung=Optimal
```

Die Messwerte beziehen sich auf das digitale Audiosignal
innerhalb von SVXLink.

Eine absolute Bewertung des HF-Frequenzhubs setzt
eine korrekt kalibrierte Empfangskette voraus.

## AudioCheck deaktivieren

In ModuleParrot.conf:

```ini
AUDIOCHECK=0
```

Anschließend SVXLink neu starten.
Die normale Parrot-Funktion bleibt erhalten.

## Backup und Rollback

V1.1x verwendet ein separates Backup-Verzeichnis.
Beim Rollback werden SVXLink-Version und Architektur geprüft.
Backups der Versionsreihe V1.0x werden nicht unterstützt.

Backups befinden sich unter:

`/var/backups/svxlink-parrot-audiocheck-v1.1x/`

Vorhandene Backups anzeigen:

```bash
clear
sudo ls -lt /var/backups/svxlink-parrot-audiocheck-v1.1x/
```

Backup prüfen:

```bash
clear
sudo ./rollback.sh --check BACKUP_DIRECTORY
```

Backup wiederherstellen:

```bash
clear
sudo ./rollback.sh --restore BACKUP_DIRECTORY
```

BACKUP_DIRECTORY durch den vollständigen Pfad
des gewünschten Backups ersetzen.

Der Installer zeigt den passenden Rollback-Befehl
nach erfolgreicher Installation an.

## Teststatus

### Erfolgreich abgeschlossen

- Portierung auf SVXLink-Commit f479562b.
- Kompilierung des ARMHF-Binärmoduls.
- Prüfung der Compiler-Einstellungen.
- Isolierte TCL-Funktionstests.
- Prüfung des TCL-Lademechanismus im Quellcode.
- TCL-Updater einschließlich Wiederholungsinstallation.
- Konfigurations-Updater einschließlich individueller Werte.
- Syntaxprüfung der Installationsskripte.

### Noch ausstehend

- Verifizierung der Originalmodul-Prüfsumme.
- Kompatibilitätsprüfung auf dem Zielsystem.
- Praktischer Installationstest.
- SVXLink-Dienststart mit V1.10.
- HF-Funktionstest mit SimplexLogic und RepeaterLogic.
- Praktischer Backup- und Rollback-Test.
- Öffentliche Freigabe.

## Quellcode

Der modifizierte Quellcode und der Patch befinden
sich in den Verzeichnissen src und patches.

Upstream-Projekt:
https://github.com/sm0svx/svxlink

## Lizenz

Der modifizierte SVXLink-C++-Quellcode steht unter
der GNU General Public License Version 2 oder später.

Siehe LICENSE und die Copyright-Hinweise im Quellcode.

## Entwicklung

OE9SAU
