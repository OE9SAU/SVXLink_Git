# GeuReflector AudioCheck – TG 9998

AudioCheck-Erweiterung für den SVXLink GeuReflector.

## Funktionen

- Audio-Pegelmessung auf Talkgroup 9998
- Live-Anzeige von RMS und Peak in dBFS
- Clipping-Erkennung
- Optionale automatische Pegelregelung (AGC)
- AGC standardmäßig deaktiviert
- Audio-Weiterleitung auf TG 9998 bleibt aktiv
- Bestehende Talker-Verwaltung bleibt erhalten
- Unterstützung für Trunk-, Twin- und Satellite-Verbindungen

## Audio-Einstellung

Die einfache Benutzeroberfläche ist für die
Mikrofoneinstellung vorgesehen.

Empfohlene Pegel:

- RMS-Zielwert: -20 dBFS
- Höchstwert: -12 dBFS

Bei deaktivierter AGC wird das Audiosignal
unverändert weitergeleitet.

## Weboberflächen

web/audiocheck.html
  Erweiterte AudioCheck-Anzeige mit AGC-Steuerung.

web/audiocheck_simple.html
  Einfache Pegelanzeige für Benutzer.

Beide Webseiten verwenden den HTTP-Endpunkt:

/audiocheck.json

## Quellcode

Die geänderten Dateien befinden sich unter:

src/svxlink/reflector/

Die Dateien sind für die Integration in den
passenden GeuReflector-Quellbaum vorgesehen.

Es handelt sich nicht um ein eigenständig
kompilierbares Projekt.

## Grundlage

Upstream:
https://github.com/audric/GeuReflector

Basis-Commit:
dbad88e8c3e0f1adb8342db190bb0b3ad00106f4

AudioCheck-Entwicklungscommit:
dc704de76889259e175f49b5a3953e7813e9a858

## Installation

Die Erweiterung muss in den passenden
GeuReflector-Quellbaum integriert und
anschließend neu kompiliert werden.

Vor einer Installation auf einem produktiven
Reflektor müssen Konfiguration und bestehende
Binärdateien gesichert werden.

Die konkrete Installationsanleitung wird
nach Prüfung des Build- und HTTP-Setups ergänzt.

## Projekt

OE9SAU
November 2026
