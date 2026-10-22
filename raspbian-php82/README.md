# PHP 8.2.35 für Raspbian 12 Bookworm (ARMHF)

Selbst kompilierte PHP-8.2.35-DEB-Pakete für **Raspberry Pi OS / Raspbian 12 Bookworm (32 Bit, ARMHF)**. Die Pakete basieren auf dem offiziellen Debian-Sicherheitsquellpaket `php8.2` in Version `8.2.35-1~deb12u1` und wurden nativ auf einem **Raspberry Pi 3 Model B+** gebaut.

> **Hinweis:** Dies ist ein unabhängiges Community-Build, kein offizielles Debian-, Raspberry-Pi-OS- oder Sury-Paketrepository. Die hier veröffentlichten Dateien werden **nicht automatisch** durch APT aktualisiert.

## Version und Plattform

| Eigenschaft | Wert |
| --- | --- |
| PHP | **8.2.35** |
| Paketversion | `8.2.35-1~deb12u1+rpi11` |
| Basis | Debian-Sicherheitsquellpaket `8.2.35-1~deb12u1` |
| Zielsystem | Raspbian 12 Bookworm, ARMHF (32 Bit) |
| Build-System | Raspberry Pi 3 Model B+ |
| Webserver-Integration | Apache 2 mit `mod_php` und `mpm_prefork` |
| Release-Tag | [`php8.2.35-rpi11`](https://github.com/OE9SAU/SVXLink_Git/releases/tag/php8.2.35-rpi11) |

Die Pakete sind für **Raspbian ARMHF** erstellt. Sie sind nicht für ARM64 (`arm64`), x86 oder andere Debian-Versionen vorgesehen. Eine erfolgreiche Installation auf weiteren Geräten oder Konfigurationen ist nicht garantiert.

## Enthaltene Release-Dateien

Das [GitHub Release](https://github.com/OE9SAU/SVXLink_Git/releases/tag/php8.2.35-rpi11) enthält diese sechs Pakete für eine Apache-Installation mit `mod_php`:

| Paket | Funktion |
| --- | --- |
| `php8.2-common` | Gemeinsame PHP-Komponenten |
| `php8.2-cli` | PHP auf der Kommandozeile |
| `php8.2-opcache` | Zend OPcache |
| `php8.2-readline` | Readline-Unterstützung |
| `libapache2-mod-php8.2` | Apache-PHP-Modul |
| `php8.2` | PHP-Metapaket |

Zusätzlich ist die Prüfsummendatei `SHA256SUMS` enthalten. GitHub zeigt unter *Assets* außerdem automatisch erzeugte Quellcodearchive (`zip`, `tar.gz`) des **gesamten Repositorys** an. Diese sind **nicht** die installierbaren PHP-DEB-Pakete.

Andere PHP-Erweiterungen wie `php8.2-mysql`, `php8.2-curl` oder `php8.2-mbstring` gehören **nicht** zu diesem sechsteiligen Release-Set. Vor einer Installation prüfen, ob die vorhandene Anwendung weitere PHP-Erweiterungen benötigt.

## Voraussetzungen

- Raspberry Pi OS / Raspbian **12 Bookworm, 32 Bit (`armhf`)**
- Funktionierende APT-Paketverwaltung und Internetzugang
- `curl` und `sha256sum` für Download und Integritätsprüfung
- Für die hier gezeigte Apache-Installation: Apache 2 mit `mod_php` / `mpm_prefork`
- Ausreichend Speicherplatz für Download, Paketinstallation und eine Sicherung der Konfiguration

Architektur und Distribution prüfen:

```bash
dpkg --print-architecture
cat /etc/os-release
```

Erwartet wird `armhf` sowie Bookworm (`VERSION_CODENAME=bookworm`).

## Schnellinstallation (empfohlen)

Für Raspberry Pi OS / Raspbian 12 Bookworm (ARMHF, 32 Bit) steht ein Installationsskript zur Verfügung.

Das Skript lädt die benötigten PHP-8.2.35-Pakete aus dem GitHub Release herunter, prüft die SHA256-Prüfsummen und installiert die Pakete über APT.
Vor der Installation sichert das Skript automatisch die vorhandene Apache- und PHP-Konfiguration unter /var/backups/php82/. Bei einem Fehler während der Sicherung wird die Installation abgebrochen.

```bash
cd ~
wget https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/main/raspbian-php82/php82_install.sh
bash -n php82_install.sh && sudo bash php82_install.sh
```

Die Installation muss bestätigt werden.

Nach erfolgreicher Installation die PHP-Version überprüfen:

```bash
php -v
```

Erwartete Version: **PHP 8.2.35**

**Hinweis:** Das Skript ist für Raspbian 12 Bookworm ARMHF vorgesehen. Es installiert PHP für Apache mit `mod_php`.

Alternativ ist die manuelle Installation der DEB-Pakete möglich. NICHT GETESTET! KI-generiert
## Installation aus GitHub Releases

### 1. Vorhandene Konfiguration sichern

Bei einer bestehenden Apache-/PHP-Installation empfiehlt sich vor dem Upgrade ein Backup:

```bash
sudo tar -czf "$HOME/apache-php-backup-$(date +%Y%m%d).tar.gz" \
  -C /etc apache2 php
```

Die Sicherung setzt voraus, dass `/etc/apache2` und `/etc/php` vorhanden sind.

### 2. Pakete herunterladen

```bash
mkdir -p "$HOME/php8.2.35-rpi11"
cd "$HOME/php8.2.35-rpi11"

BASE_URL='https://github.com/OE9SAU/SVXLink_Git/releases/download/php8.2.35-rpi11'
VERSION='8.2.35-1~deb12u1+rpi11'

for pkg in php8.2-common php8.2-cli php8.2-opcache php8.2-readline libapache2-mod-php8.2; do
  curl -fL --retry 3 -O "$BASE_URL/${pkg}_${VERSION}_armhf.deb" || exit 1
done

curl -fL --retry 3 -O "$BASE_URL/php8.2_${VERSION}_all.deb" || exit 1
curl -fL --retry 3 -O "$BASE_URL/SHA256SUMS" || exit 1
```

### 3. SHA256-Prüfsummen prüfen

```bash
sha256sum -c SHA256SUMS
```

**Alle sechs Pakete müssen `OK` melden.** Bei einem Fehler nicht installieren. Die Prüfsummen erkennen versehentliche oder nachträgliche Veränderungen gegenüber der veröffentlichten `SHA256SUMS`-Datei; für eine vertrauenswürdige Herkunft müssen Release und Repository zusätzlich selbst überprüft werden.

### 4. Installation zunächst simulieren

```bash
sudo apt-get -s install \
  ./php8.2-common_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-cli_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-opcache_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-readline_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./libapache2-mod-php8.2_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2_8.2.35-1~deb12u1+rpi11_all.deb
```

Die Simulation darf keine unerwarteten Paketentfernungen oder Abhängigkeitskonflikte melden. Vor allem bei vorhandenen PHP-Erweiterungen oder gemischten Paketquellen die vorgeschlagenen Änderungen sorgfältig prüfen.

### 5. Installieren

Wenn die Simulation erfolgreich ist, denselben Befehl **ohne `-s`** ausführen:

```bash
sudo apt-get install \
  ./php8.2-common_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-cli_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-opcache_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2-readline_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./libapache2-mod-php8.2_8.2.35-1~deb12u1+rpi11_armhf.deb \
  ./php8.2_8.2.35-1~deb12u1+rpi11_all.deb
```

Bei Rückfragen zu lokal angepassten Konfigurationsdateien die Unterschiede prüfen und bewusst entscheiden, welche Version beibehalten werden soll.

## Installation überprüfen

PHP CLI und Paketversionen:

```bash
php -v

dpkg-query -W -f='${Package} ${Version}\n' \
  php8.2 php8.2-cli php8.2-common php8.2-opcache \
  php8.2-readline libapache2-mod-php8.2
```

Erwartet: PHP CLI **8.2.35** und die Paketversion **`8.2.35-1~deb12u1+rpi11`**.

Apache-Konfiguration und geladene Module:

```bash
sudo apache2ctl configtest
apache2ctl -M 2>/dev/null | grep -E 'php|mpm'
sudo systemctl restart apache2
systemctl status apache2 --no-pager
```

Erwartet: `Syntax OK`, `php_module`, `mpm_prefork_module` und ein laufender Apache-Dienst.

Optional kann die PHP-Ausführung über den lokalen Standard-VHost geprüft werden (nur wenn `/var/www/html` tatsächlich dessen DocumentRoot ist):

```bash
printf '%s\n' '<?php echo PHP_VERSION, PHP_EOL; ?>' | \
  sudo tee /var/www/html/php-version-test.php >/dev/null

curl -fsS http://127.0.0.1/php-version-test.php
sudo rm -f /var/www/html/php-version-test.php
```

Erwartete Ausgabe: `8.2.35`. Die Testdatei danach unbedingt entfernen.

## Selbst kompilieren

Die Pakete wurden aus den **offiziellen Debian-Quellen** auf einem Raspberry Pi 3 Model B+ gebaut. Für einen eigenen Build werden aktivierte `deb-src`-Quellen für Debian Bookworm einschließlich der passenden Sicherheitsquellen, die erforderlichen Build-Abhängigkeiten und ausreichend Zeit sowie freier Speicher benötigt.

Beispiel für den grundlegenden Ablauf:

```bash
sudo apt update
sudo apt install build-essential devscripts dpkg-dev

mkdir -p "$HOME/php-build"
cd "$HOME/php-build"

apt source php8.2=8.2.35-1~deb12u1
cd php8.2-8.2.35

# Lokale Paketrevision setzen; erfordert devscripts und einen Editor
# bzw. entsprechende dch-Konfiguration.
dch --local '+rpi1' 'Rebuild for Raspbian 12 ARMHF.'

DEB_BUILD_OPTIONS='parallel=1' dpkg-buildpackage -us -uc -b -j1
```

**Wichtig:** `apt source` erfordert passende aktivierte Quellpaket-Repositories; `dpkg-buildpackage` benötigt außerdem die vom Quellpaket geforderten Build-Abhängigkeiten. Diese müssen vorab installiert werden, zum Beispiel nach Prüfung mit `dpkg-checkbuilddeps` und der für das System geeigneten Methode zur Installation der Build-Abhängigkeiten. Der Build kann auf einem Raspberry Pi 3 B+ mehrere Stunden dauern.

Die hier veröffentlichten Binärpakete tragen die lokale Revision `+rpi11`. Der gezeigte `dch`-Aufruf ist ein Beispiel für einen eigenen lokalen Rebuild; die exakte Revisionsnummer muss vor dem Build entsprechend gesetzt und mit `dpkg-parsechangelog -S Version` geprüft werden.

## Getestete Umgebung

Die sechs Release-Pakete wurden auf einem Raspberry Pi 3 Model B+ unter Raspbian 12 Bookworm ARMHF installiert und überprüft:

- APT-Installationssimulation ohne Paketentfernungen oder Abhängigkeitskonflikte
- PHP CLI meldet `8.2.35`
- Apache startet erfolgreich mit `mod_php` und `mpm_prefork`
- Lokaler PHP-Aufruf über Apache liefert `8.2.35`
- SHA256-Prüfung aller sechs Release-DEBs erfolgreich

Diese Tests bestätigen die genannte Umgebung, ersetzen aber keine vollständige Kompatibilitätsprüfung für andere Installationen.

## Hinweise zu Sicherheit und Updates

- Das Paketset ist eine **Momentaufnahme**. Neue Sicherheitsupdates müssen eigenständig verfolgt und bei Bedarf neu gebaut beziehungsweise aus einer vertrauenswürdigen Paketquelle installiert werden.
- Es handelt sich um **lokal installierte DEB-Dateien**, nicht um ein APT-Repository. `apt update` lädt keine neuen Releases aus diesem GitHub-Projekt.
- Bei Verwendung mehrerer PHP-Paketquellen (z. B. Sury und Debian/Raspbian) vor jedem Upgrade `apt-cache policy` und die geplanten Paketänderungen prüfen.
- PHP 8.2 ist eine ältere PHP-Version; vor einem langfristigen Einsatz die aktuelle Unterstützung und Sicherheitsversorgung prüfen.
- Das Release enthält keine zusätzlichen PHP-Erweiterungen und keine `-dbgsym`-Pakete.

## Fehlerbehebung

**APT meldet Abhängigkeitskonflikte:** Mit `apt-get -s install ...` zunächst nur simulieren. Architektur (`dpkg --print-architecture`), Release-Version und vorhandene PHP-Pakete prüfen. Nicht mit `dpkg --force-*` erzwingen.

**Apache meldet `AH00558` wegen `ServerName`:** Das ist üblicherweise eine unkritische Warnung. Optional kann ein globaler `ServerName` konfiguriert werden.

**PHP CLI zeigt 8.2.35, die Website nicht:** Apache-Modul, VirtualHost, gegebenenfalls PHP-FPM-Konfiguration und den tatsächlich angesprochenen Webserver prüfen.

**Zusätzliche Erweiterungen fehlen:** Dieses Release enthält nur das dokumentierte Basisset. Benötigte Erweiterungen müssen in kompatibler Version separat bereitgestellt werden.

## Quellen

- [PHP-Projekt](https://www.php.net/)
- [Debian-Paketinformationen zu php8.2](https://tracker.debian.org/pkg/php8.2)
- [Debian-Sicherheitsinformationen](https://www.debian.org/security/)
- [GitHub Release: php8.2.35-rpi11](https://github.com/OE9SAU/SVXLink_Git/releases/tag/php8.2.35-rpi11)

---

**Projekt:** [OE9SAU/SVXLink_Git](https://github.com/OE9SAU/SVXLink_Git) · Verzeichnis: `raspbian-php82`
