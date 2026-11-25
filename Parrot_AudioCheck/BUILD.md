# SVXLink Parrot AudioCheck V1.02 – Kompilierungsanleitung

## Quellcode-Basis

Upstream:
https://github.com/sm0svx/svxlink

SVXLink-Version:
1.8.99.11@24.02-48-g9d6e0c79

Git-Commit:
9d6e0c790a04d3517e2536cf012bfbe272072a58

## Getestete Build-Umgebung

- Raspberry Pi OS / Raspbian 12 Bookworm
- Architektur armhf (32 Bit)
- GCC 12.2.0
- CMake 3.25.1
- Interne SVXLink-Abtastrate: 16000 Hz

## Enthaltene Quellcode-Dateien

- src/ModuleParrot.cpp
- src/ModuleParrot.h
- patches/AudioCheck-V1.02.patch

Es wurden ausschließlich ModuleParrot.cpp und
ModuleParrot.h verändert.

## 1. SVXLink-Quellcode herunterladen

```bash
clear
cd "$HOME"
git clone https://github.com/sm0svx/svxlink.git svxlink-audiocheck-build
cd svxlink-audiocheck-build
git checkout 9d6e0c790a04d3517e2536cf012bfbe272072a58
```

## 2. AudioCheck-Patch anwenden

```bash
clear
cd "$HOME/svxlink-audiocheck-build"

PATCH="$HOME/SVXLink_Git/Parrot_AudioCheck/patches/AudioCheck-V1.02.patch"

git apply --check "$PATCH"
git apply "$PATCH"

git diff --stat
```

## 3. Build vorbereiten

Die erforderlichen Entwicklungsbibliotheken müssen
entsprechend der SVXLink-Build-Dokumentation installiert sein.

```bash
clear
cd "$HOME/svxlink-audiocheck-build"

cmake -S src -B src/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINTERNAL_SAMPLE_RATE=16000
```

## 4. Parrot-Modul kompilieren

```bash
clear
cd "$HOME/svxlink-audiocheck-build"

cmake --build src/build --target ModuleParrot -j2
```

Bei geringem Arbeitsspeicher kann alternativ
mit -j1 kompiliert werden.

## 5. Binärmodul prüfen

```bash
clear
cd "$HOME/svxlink-audiocheck-build"

file src/build/lib/ModuleParrot.so
ldd src/build/lib/ModuleParrot.so
sha256sum src/build/lib/ModuleParrot.so
```

## Referenz-Binärmodul

Das mitgelieferte ARMHF-Binärmodul besitzt folgende
SHA256-Prüfsumme:

2c1f6bcffeed9a5080e13718f39be7d5dd744b990aff949a019c24a2f6636bc1

Bei einer eigenen Kompilierung kann die Prüfsumme
aufgrund unterschiedlicher Build-Einstellungen abweichen.

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
