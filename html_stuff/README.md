# Icon und Favicon Update SVXLink Austria

<p align="center">
  <img width="100" height="500" src="svxlink.ico">
</p>

![Fav](favicon.ico)

## Dieses Kommando aktualisiert die Dateien favicon.ico und svxlink.ico im Verzeichnis/var/www/html/images für SvxLink Dashboard Ver 2.1 © G4NAB, SP2ONG, SP0DZ 2021-2026

### Bestehende Dateien werden vor dem Überschreiben gesichert (*_orig.ico)

```
cd /var/www/html/images && \
sudo cp favicon.ico favicon_orig.ico && \
sudo cp svxlink.ico svxlink_orig.ico && \
sudo curl -fL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/html_stuff/favicon.ico -o favicon.ico && \
sudo curl -fL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/html_stuff/svxlink.ico -o svxlink.ico && \
sudo chmod 644 favicon.ico svxlink.ico
```
