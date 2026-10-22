# PHP 8.2.35 für Raspberry Pi OS / Raspbian 12 (Bookworm, ARMHF)

![Status](https://img.shields.io/badge/Status-Build%20l%C3%A4uft-orange)
![PHP](https://img.shields.io/badge/PHP-8.2.35-blue)
![Debian](https://img.shields.io/badge/Debian-12%20Bookworm-A81D33)
![Architektur](https://img.shields.io/badge/Architektur-ARMHF%20(32--Bit)-informational)

Dieses Projekt dokumentiert den **eigenständigen Build von PHP 8.2.35 aus den offiziellen Debian-Quellen** auf einem **Raspberry Pi 3 Model B+** mit Raspberry Pi OS / Raspbian 12 (Bookworm, 32 Bit, ARMHF).

Ziel ist es, nach erfolgreichem Build und Prüfung installierbare Debian-Pakete (`.deb`) über [GitHub Releases](https://github.com/OE9SAU/SVXLink_Git/releases) bereitzustellen. Der Schwerpunkt liegt auf PHP für **Apache mit `mod_php`**.

> [!IMPORTANT]
> **Projektstatus: Build läuft (Stand: 22.10.2026).** Die selbst gebauten Pakete sind noch nicht als erfolgreich gebaut, installiert, getestet oder veröffentlicht bestätigt. Diese README enthält daher **keinen angeblich funktionsfähigen Release-Download**.

## Hintergrund

Ausgangspunkt war die auf dem verwendeten System über das Sury-Repository angebotene Version **PHP 8.2.34**. Debian hat am 21. Oktober 2026 die Sicherheitsaktualisierung **`8.2.35-1~deb12u1`** für Bookworm veröffentlicht. Sie behebt unter anderem **CVE-2026-109618** und **CVE-2026-109619**.

**Wichtig:** Debian stellt die Version `8.2.35-1~deb12u1` inzwischen auch als offizielles **ARMHF-Binärpaket** bereit. Vor einem Eigenbau oder einer Installation aus diesem Projekt sollte deshalb geprüft werden, ob das Sicherheitsupdate bereits aus den regulären Debian-Paketquellen verfügbar ist. Die hier erstellten Pakete sind ein **unabhängiger, lokal gebauter Paketstand** und kein offizieller Debian-Release.

| Eigenschaft | Wert |
| --- | --- |
| PHP-Version | `8.2.35` |
| Debian-Quellpaket | `8.2.35-1~deb12u1` |
| Geplante eigene Paketversion | `8.2.35-1~deb12u1+rpi11` |
| Zielsystem | Raspberry Pi OS / Raspbian 12 Bookworm |
| Architektur | `armhf` (32 Bit) |
| Build-Hardware | Raspberry Pi 3 Model B+ |
| Webserver-Anbindung | Apache 2 mit `mod_php` |
| Build-Status | In Arbeit; mehrere Stunden Laufzeit möglich |

## Voraussetzungen

- Raspberry Pi mit einem **ARMHF-/32-Bit-Bookworm-System**; der bisherige Build erfolgt auf einem Raspberry Pi 3 Model B+.
- Aktuelle, korrekt konfigurierte Debian-/Raspberry-Pi-OS-Paketquellen einschließlich passender Sicherheitsaktualisierungen.
- Genügend freier Speicherplatz für Quellpaket, Build-Abhängigkeiten, temporäre Dateien und erzeugte Pakete.
- Ausreichend Zeit: Der Build kann auf einem Raspberry Pi 3 Model B+ **mehrere Stunden** benötigen.
- Für die Apache-Installation: Apache 2 und eine bestehende PHP-8.2-Konfiguration oder eine entsprechend vorbereitete Neuinstallation.

System und verfügbare Paketversionen prüfen:

```bash
cat /etc/os-release
dpkg --print-architecture
uname -m
php -v
apt-cache policy php8.2-cli libapache2-mod-php8.2
```

Erwartet wird `armhf` bei `dpkg --print-architecture`. `uname -m` kann beispielsweise `armv7l` ausgeben. **ARMHF ist nicht ARM64.**

## Benötigte PHP-Pakete

Für die vorgesehene Apache-Konfiguration mit `mod_php` werden diese fünf Pakete benötigt:

| Paket | Aufgabe |
| --- | --- |
| `php8.2-common` | Gemeinsame PHP-Dateien und Module |
| `php8.2-cli` | PHP auf der Kommandozeile |
| `php8.2-opcache` | Opcode-Cache |
| `php8.2-readline` | Readline-Unterstützung für CLI |
| `libapache2-mod-php8.2` | Apache-PHP-Modul |

Je nach System und Paketmetadaten können **weitere Abhängigkeiten** erforderlich sein. Zusätzliche PHP-Erweiterungen wie `php8.2-mysql`, `php8.2-xml`, `php8.2-mbstring` oder `php8.2-curl` sind **nicht** Bestandteil dieser Fünferliste und müssen gegebenenfalls in kompatibler Version installiert werden.

## Build aus offiziellen Debian-Quellen

Die folgenden Schritte beschreiben einen nachvollziehbaren manuellen Debian-Paketbuild. Sie setzen **keine repositoryspezifischen Skripte** voraus.

### 1. Build-Werkzeuge installieren

```bash
sudo apt update
sudo apt install --no-install-recommends \
  build-essential devscripts dpkg-dev debhelper fakeroot \
  ca-certificates
```

Für `apt source` und `apt build-dep` müssen passende **`deb-src`-Einträge** für Bookworm und Bookworm-Security aktiviert sein. Deren Konfiguration hängt von der jeweiligen Raspberry-Pi-OS-Installation ab. Die Quellpakete müssen aus einer vertrauenswürdigen, signierten Debian-Paketquelle stammen.

### 2. Debian-Quellpaket beziehen

```bash
mkdir -p ~/php82-build
cd ~/php82-build
apt source php8.2=8.2.35-1~deb12u1
```

Falls diese Version nicht gefunden wird, zuerst die Quellpaketquellen und deren Aktualität prüfen. Die Quellen sind auch auf der [offiziellen Debian-Paketseite](https://packages.debian.org/source/bookworm/php8.2) dokumentiert.

### 3. Build-Abhängigkeiten installieren

```bash
sudo apt build-dep php8.2
```

**Hinweis:** `apt build-dep` löst die Abhängigkeiten anhand der aktivierten Quellpaketquellen auf. Vor dem Build sicherstellen, dass die passenden Bookworm-Quellen verwendet werden. Falls der Paketstand inzwischen gewechselt hat, die Abhängigkeiten mit dem `Build-Depends`-Feld der konkret heruntergeladenen `.dsc`-Datei abgleichen.

### 4. Eigene Paketrevision setzen

In das entpackte Quellverzeichnis wechseln:

```bash
cd ~/php82-build/php8.2-8.2.35
```

Der Verzeichnisname ist abhängig vom entpackten Quellpaket und sollte bei Bedarf mit `ls` überprüft werden.

Die lokale Revision wird über `debian/changelog` gesetzt:

```bash
dch --local +rpi11 --distribution bookworm \
  'Lokaler ARMHF-Build für Raspberry Pi OS Bookworm.'
```

**Vor dem Build unbedingt kontrollieren:**

```bash
dpkg-parsechangelog -S Version
```

Der Wert muss **`8.2.35-1~deb12u1+rpi11`** lauten. Die `dch`-Option `--local` kann je nach Ausgangszustand des Changelogs und Werkzeugverhalten eine andere Versionszeichenfolge erzeugen. Falls nötig, den obersten Eintrag in `debian/changelog` korrigieren. Die hier dokumentierte Paketversion ist das **beabsichtigte Ergebnis**, kein bereits verifizierter Build-Artefakt.

### 5. Build starten

```bash
DEB_BUILD_OPTIONS="parallel=1" dpkg-buildpackage -us -uc -b -j1
```

Die Optionen bedeuten:

- `parallel=1` und `-j1`: parallele Build-Arbeit begrenzen, um den Arbeitsspeicher des Raspberry Pi zu schonen.
- `-us -uc`: Quellpaket-/Changes-Signaturen beim lokalen Build nicht erstellen.
- `-b`: Binärpakete bauen.

Der Build kann **mehrere Stunden** dauern. Ein erfolgreicher Programmstart oder das Vorhandensein einzelner `.deb`-Dateien ist noch kein Nachweis, dass alle benötigten Pakete korrekt fertiggestellt wurden.

### 6. Ergebnisse kontrollieren

Nach erfolgreichem Abschluss im übergeordneten Build-Verzeichnis:

```bash
cd ~/php82-build
find . -maxdepth 1 -type f -name '*_armhf.deb' -print
```

Metadaten eines tatsächlich vorhandenen Pakets lassen sich so prüfen:

```bash
dpkg-deb -f ./php8.2-cli_8.2.35-1~deb12u1+rpi11_armhf.deb \
  Package Version Architecture Depends
```

Der Dateiname in diesem Beispiel setzt voraus, dass genau dieses Paket erfolgreich erzeugt wurde. Bei abweichendem Dateinamen entsprechend anpassen.

## Installation der ARMHF-DEB-Pakete

> [!WARNING]
> **Noch keine freigegebene Installationsanleitung für einen veröffentlichten Build.** Die folgenden Befehle sind für den Zeitpunkt vorgesehen, an dem die fünf Pakete tatsächlich gebaut, geprüft und lokal bereitgestellt wurden.

### 1. Offizielle Paketquellen zuerst prüfen

```bash
sudo apt update
apt-cache policy php8.2-cli libapache2-mod-php8.2
```

Wenn PHP 8.2.35 bereits über vertrauenswürdige Paketquellen erhältlich ist, ist deren regulärer Sicherheitsupdate-Pfad in der Regel vorzuziehen.

### 2. Lokale Pakete installieren (erst nach erfolgreichem Build)

In einem Verzeichnis, das die **fünf tatsächlich erzeugten und geprüften** DEB-Dateien enthält:

```bash
sudo apt install \
  ./php8.2-common_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-cli_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-opcache_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-readline_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./libapache2-mod-php8.2_8.2.35-1~deb12u1+rpi11_armhf.deb
```

Dies ist **ein Beispiel für die Installation lokaler Build-Dateien**, kein Downloadbefehl und keine Aussage über deren derzeitige Existenz. APT löst zusätzliche Abhängigkeiten aus den konfigurierten Quellen auf. **Vor der Bestätigung die von APT vorgeschlagenen Installationen, Downgrades und Entfernungen sorgfältig lesen.**

Falls weitere PHP-8.2-Erweiterungen installiert sind, ihre Paketversionen und Abhängigkeiten ebenfalls überprüfen. Eine Mischung aus inkompatiblen Paketständen oder Paketquellen kann die Installation verhindern oder bestehende Anwendungen beeinträchtigen.

### 3. Apache-Konfiguration prüfen

```bash
apache2ctl -M | grep php
sudo apache2ctl configtest
```

Bei einem bestehenden, korrekt konfigurierten `mod_php`-Setup kann nach erfolgreicher Paketinstallation ein Neustart nötig sein:

```bash
sudo systemctl restart apache2
sudo systemctl status apache2 --no-pager
```

**Nicht ungeprüft PHP-FPM und `mod_php` vermischen.** Die Aktivierung des Apache-Moduls sowie die verwendete MPM-Konfiguration müssen zur bestehenden Installation passen.

## Versions- und Funktionsprüfung

CLI-Version und installierte Paketstände:

```bash
php -v
php -m
dpkg-query -W \
  php8.2-common php8.2-cli php8.2-opcache \
  php8.2-readline libapache2-mod-php8.2
```

Apache-Modul und Webserver-Konfiguration:

```bash
apache2ctl -M | grep php
sudo apache2ctl configtest
systemctl status apache2 --no-pager
```

**Wichtig:** `php -v` überprüft primär die CLI-Version und belegt **nicht automatisch**, dass Apache dieselbe PHP-Version lädt. Für die Webserver-Prüfung sind die geladenen Apache-Module und ein kontrollierter HTTP-Funktionstest entscheidend. Eine öffentlich erreichbare `phpinfo()`-Datei sollte nicht dauerhaft angelegt werden.

## Veröffentlichung über GitHub Releases (geplant)

Nach Abschluss des Builds und erfolgreichen Installations-/Funktionstests ist vorgesehen, die ARMHF-DEB-Dateien im Repository unter **[Releases](https://github.com/OE9SAU/SVXLink_Git/releases)** bereitzustellen.

Vor einer Veröffentlichung sollten mindestens folgende Punkte erfüllt sein:

- Alle fünf benötigten Pakete wurden erfolgreich erzeugt und ihre Versions-/Architekturmetadaten geprüft.
- Installation und Abhängigkeitsauflösung auf einem passenden Bookworm-ARMHF-Testsystem wurden verifiziert.
- PHP-CLI, Apache-Konfiguration und ein tatsächlicher PHP-Webaufruf funktionieren.
- Prüfsummen (z. B. SHA-256) und ein klarer Hinweis auf den inoffiziellen Build liegen vor.
- Bekannte Einschränkungen und zusätzlich benötigte PHP-Erweiterungen sind dokumentiert.

Es gibt derzeit **keinen hier bestätigten Release mit fertigen Paketen**. Bitte keine Dateinamen oder Release-Tags als veröffentlichte Downloads interpretieren.

## Sicherheit und Wartung

- **Inoffizielle Pakete:** Die `+rpi11`-Pakete werden lokal erstellt und sind nicht von Debian signierte oder durch Debian betreute Binärpakete.
- **Quellenintegrität:** Offizielle, über APT signaturgeprüfte Debian-Quellen verwenden. Fremde `.deb`-Dateien nicht ungeprüft installieren.
- **Sicherheitsupdates:** Ein lokal installiertes Paket kann wegen seiner Versionsnummer länger als ein neueres offizielles Paket bevorzugt werden. Updates deshalb aktiv überwachen; bei neuen Debian-Sicherheitsversionen den Versionsvergleich mit `apt-cache policy` prüfen.
- **Paketquellen:** Debian, Raspberry Pi OS und Sury nicht ohne Prüfung von Herkunft, Priorität und Abhängigkeiten mischen.
- **Produktivsysteme:** Vor dem Austausch von PHP-Paketen ein Backup der Anwendung, Konfiguration und Datenbank erstellen. Zuerst auf einem Testsystem prüfen.
- **Paketintegrität:** Veröffentlichte Dateien nach Möglichkeit mit SHA-256-Prüfsummen versehen und vor Installation vergleichen.
- **Sicherheitsstatus:** Eine neuere PHP-Versionsnummer allein ersetzt keine laufende Pflege des Systems und seiner Erweiterungen.

## Fehlerbehebung

### `apt source` findet PHP 8.2.35 nicht

```bash
sudo apt update
apt-cache showsrc php8.2 | grep -E '^(Package|Version):'
```

Falls `apt-cache showsrc` keine Daten liefert, `deb-src`-Einträge für Bookworm und Bookworm-Security prüfen. Nicht auf eine beliebige fremde Quelle ausweichen.

### `apt build-dep` meldet unerfüllbare Abhängigkeiten

Paketquellen, Architektur und Quellpaketversion prüfen:

```bash
dpkg --print-architecture
apt-cache policy
```

Insbesondere gemischte Repositories können widersprüchliche Abhängigkeiten verursachen.

### Build bricht ab oder das System wird sehr langsam

Den Build mit nur einem Job ausführen, freien Speicher und RAM prüfen:

```bash
free -h
df -h
```

Die konkrete Fehlermeldung im Build-Log ist entscheidend. Einen Abbruch nicht allein aufgrund langer Laufzeit annehmen.

### Paketversion stimmt nicht

```bash
dpkg-parsechangelog -S Version
```

Den obersten Eintrag in `debian/changelog` auf die beabsichtigte Version `8.2.35-1~deb12u1+rpi11` korrigieren und anschließend neu bauen.

### APT möchte Pakete entfernen oder zurückstufen

Die Installation abbrechen und zuerst die Versions- und Abhängigkeitslage prüfen:

```bash
apt-cache policy php8.2-common php8.2-cli libapache2-mod-php8.2
dpkg -l 'php8.2*' 'libapache2-mod-php8.2'
```

Nicht mit `dpkg --force-*` erzwingen.

### PHP CLI funktioniert, Apache aber nicht

```bash
sudo apache2ctl configtest
apache2ctl -M | grep php
sudo journalctl -u apache2 -n 80 --no-pager
```

Das CLI-Paket und das Apache-Modul sind getrennte Komponenten. Auch die Apache-MPM- und Modulkonfiguration kontrollieren.

## Quellen und weiterführende Links

- [Debian: Quellpaket php8.2 für Bookworm](https://packages.debian.org/source/bookworm/php8.2)
- [Debian: Binärpaket php8.2 für Bookworm](https://packages.debian.org/bookworm/php8.2)
- [Debian LTS: DLA-4848-1 (21.10.2026)](https://lists.debian.org/debian-lts-announce/2026/10/msg00042.html)
- [Debian Security Tracker: php8.2](https://security-tracker.debian.org/tracker/source-package/php8.2)
- [Offizielles Debian-Sicherheitsarchiv für php8.2](https://security.debian.org/debian-security/pool/updates/main/p/php8.2/)
- [Debian PHP Packaging (Salsa)](https://salsa.debian.org/php-team/php/-/tree/debian/main/8.2)
- [PHP-Projekt](https://www.php.net/)
- [Dieses Repository](https://github.com/OE9SAU/SVXLink_Git/tree/main/raspbian-php82)

## Projektstatus und Haftung

**Stand: 22. Oktober 2026 — Build in Arbeit.** Diese Dokumentation wird nach erfolgreichem Paketbuild, Installationstest und einer möglichen Release-Veröffentlichung aktualisiert.

Dieses Projekt ist ein **unabhängiger Community-Build** und steht in keiner offiziellen Verbindung zu Debian, Raspberry Pi oder dem PHP-Projekt. Die Nutzung eigener Binärpakete erfolgt auf eigene Verantwortung. Es wird keine Gewähr für Funktionsfähigkeit, Sicherheit oder Kompatibilität übernommen.
