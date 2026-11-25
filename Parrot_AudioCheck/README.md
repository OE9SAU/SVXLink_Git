# SVXLink Parrot AudioCheck V1.02


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
- Update von AudioCheck V1.0 und V1.01

## Kompatibilität

Das mitgelieferte Binärmodul ist vorgesehen für:

- Raspberry Pi OS / Raspbian 12 Bookworm
- Architektur: armhf (32 Bit)
- SVXLink: 1.8.99.11@24.02-48-g9d6e0c79
- Deutsche SVXLink-Sprachdateien

Andere SVXLink-Versionen und Architekturen werden
vom Installer nicht unterstützt.

## Installation

Repository herunterladen:

```bash
clear
git clone https://github.com/OE9SAU/SVXLink_Git.git
cd SVXLink_Git/Parrot_AudioCheck
```

Kompatibilität prüfen:

```bash
clear
sudo ./install.sh --check
```

Installation starten:

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
Toleranz von +/-3 dB gelten folgende Bewertungsstufen:

| RMS-Pegel | Sprachbewertung |
|-----------|-----------------|
| Unter -30 dBFS | Deutlich zu leise |
| -30 bis unter -23 dBFS | Etwas zu leise |
| -23 bis -17 dBFS | Optimal |
| Über -17 bis -14 dBFS | Etwas zu laut |
| Über -14 dBFS | Deutlich zu laut |

Die Grenzwerte sind Empfehlungen für dieses AudioCheck-System
und keine allgemeingültige Funknorm.

## Konfiguration

Datei: `/etc/svxlink/svxlink.d/ModuleParrot.conf`

```ini
AUDIOCHECK=1
AUDIOCHECK_TARGET_RMS=-20
AUDIOCHECK_TOLERANCE=3
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

Beispiel einer Messung:

```text
Parrot: AudioCheck V1.02: RMS=-21.80 dBFS, Peak=-4.17 dBFS, Bewertung=Optimal
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

Backups befinden sich unter:

`/var/backups/svxlink-parrot-audiocheck/`

Vorhandene Backups anzeigen:

```bash
clear
sudo ls -lt /var/backups/svxlink-parrot-audiocheck/
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

- V1.02 auf SimplexLogic getestet
- V1.0 auf RepeaterLogic getestet
- Installer auf bestehender V1.02 getestet
- TCL-Updates von V1.0 und V1.01 getestet
- Dienststart nach Rollback erfolgreich
- HF-Test nach automatischer Installation noch ausstehend
- Repeater-Update auf V1.02 noch ausstehend

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
