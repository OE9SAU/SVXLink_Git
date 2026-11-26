# SVXLink Parrot AudioCheck V1.10 – Kompilierungsanleitung

## Quellcode-Basis

Upstream:
https://github.com/sm0svx/svxlink

SVXLink-Version:
1.9.99.36@25.05.1-83-gf479562b

Git-Commit:
f479562b4f441da114182c0a0beb0095adb73400

## Getestete Build-Umgebung

- Raspberry Pi OS / Raspbian 12 Bookworm
- Architektur armhf (32 Bit)
- GCC 12.2.0
- CMake 3.25.1
- libsigc++ 2.12.0
- C++11
- Interne SVXLink-Abtastrate: 16000 Hz

## Enthaltene Quellcode-Dateien

- src/ModuleParrot.cpp
- src/ModuleParrot.h
- patches/AudioCheck-V1.10.patch

Es wurden ausschließlich ModuleParrot.cpp und
ModuleParrot.h verändert.

## 1. SVXLink-Quellcode herunterladen

```bash
clear
cd "$HOME"
git clone https://github.com/sm0svx/svxlink.git svxlink-audiocheck-v1.10-build
cd svxlink-audiocheck-v1.10-build
git checkout f479562b4f441da114182c0a0beb0095adb73400
```

## 2. AudioCheck-Patch anwenden

```bash
clear
cd "$HOME/svxlink-audiocheck-v1.10-build"

PATCH="$HOME/Parrot_AudioCheck_V1.10/patches/AudioCheck-V1.10.patch"

git apply --check "$PATCH"
git apply "$PATCH"

git diff --stat
```

## 3. Build vorbereiten

Die erforderlichen Entwicklungsbibliotheken müssen
entsprechend der SVXLink-Build-Dokumentation installiert sein.

```bash
clear
cd "$HOME/svxlink-audiocheck-v1.10-build"

cmake -S src -B src/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINTERNAL_SAMPLE_RATE=16000 \
    -DUSE_QT=OFF
```

## 4. Parrot-Modul kompilieren

```bash
clear
cd "$HOME/svxlink-audiocheck-v1.10-build"

cmake --build src/build --target ModuleParrot -j2
```

Bei geringem Arbeitsspeicher kann alternativ
mit -j1 kompiliert werden.

## 5. Binärmodul prüfen

```bash
clear
cd "$HOME/svxlink-audiocheck-v1.10-build"

file src/build/lib/ModuleParrot.so
ldd src/build/lib/ModuleParrot.so
sha256sum src/build/lib/ModuleParrot.so
```

## Referenz-Binärmodul

Das mitgelieferte ARMHF-Binärmodul besitzt folgende
SHA256-Prüfsumme:

0ea27384bd3ea0fac8bc0cdeb20c2aeafa57a8bf0adef3ed31e633a92e3bd4b5

Bei einer eigenen Kompilierung kann die Prüfsumme
aufgrund unterschiedlicher Build-Einstellungen abweichen.

## Entwicklungsstatus

V1.10 ist eine experimentelle Version fuer die neue
SVXLink-Quellcode-Basis f479562b.

Die Kompilierung und isolierte TCL-Funktionstests
wurden erfolgreich abgeschlossen.

Der Installations-, Laufzeit- und HF-Test auf dem
Zielsystem steht noch aus.

## Hinweise

- Eine erfolgreiche Kompilierung garantiert keine ABI-Kompatibilität.
- Das Modul muss zur installierten SVXLink-Version passen.
- Der Installer akzeptiert nur bekannte Modul-Prüfsummen.
- Selbst kompilierte Module werden nicht automatisch unterstützt.
- Vor einer manuellen Installation ist ein Backup erforderlich.
- Andere Architekturen und SVXLink-Versionen wurden nicht getestet.
- Die Kompilierung allein installiert keine Konfiguration,
  TCL-Erweiterung oder Sprachdateien.

## Lizenz

GNU General Public License Version 2 oder später.

Siehe LICENSE und die Copyright-Hinweise im Quellcode.

## Entwicklung

OE9SAU
