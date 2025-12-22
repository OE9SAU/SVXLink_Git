#!/usr/bin/env bash
set -e

USER_HOME=$(getent passwd "${SUDO_USER:-pi}" | cut -d: -f6)
TARGET="$USER_HOME/oled_sh1106.py"

apt update
apt install -y python3-pip python3-pil python3-smbus i2c-tools
python3 -m pip install --upgrade luma.oled

curl -fsSL https://raw.githubusercontent.com/OE9SAU/oled-ip-sh1106/main/oled_sh1106.py \
  -o "$TARGET"

chmod +x "$TARGET"

cat >/etc/systemd/system/oled-sh1106.service <<EOF
[Unit]
Description=SH1106 OLED Display
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $TARGET
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now oled-ip.service
