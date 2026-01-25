Icon-Update aus GitHub

Dieses Kommando aktualisiert die Dateien favicon.ico und svxlink.ico im Verzeichnis
/var/www/html/images.

Ablauf

Bestehende Dateien werden vor dem Überschreiben gesichert (*_orig.ico)

Aktuelle Versionen werden direkt aus GitHub geladen

Dateirechte werden korrekt gesetzt (644)

```
cd /var/www/html/images && \
sudo cp favicon.ico favicon_orig.ico && \
sudo cp svxlink.ico svxlink_orig.ico && \
sudo curl -fL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/html_stuff/favicon.ico -o favicon.ico && \
sudo curl -fL https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/html_stuff/svxlink.ico -o svxlink.ico && \
sudo chmod 644 favicon.ico svxlink.ico
```
