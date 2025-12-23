#!/usr/bin/env bash
set -euo pipefail

RUN_AS="${SUDO_USER:-${USER:-pi}}"
USER_HOME="$(getent passwd "$RUN_AS" | cut -d: -f6)"
TARGET="$USER_HOME/oled_sh1106.py"
VENV_DIR="$USER_HOME/.venvs/oled-sh1106"

apt update
apt install -y python3-pip python3-venv python3-pil python3-smbus i2c-tools curl

# optional, aber oft nötig: Service-User darf auf /dev/i2c-* zugreifen
usermod -aG i2c "$RUN_AS" || true

# venv anlegen + luma.oled installieren (umgeht PEP 668 sauber)
install -d -m 0755 "$VENV_DIR"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install --upgrade luma.oled

curl -fsSL "https://raw.githubusercontent.com/OE9SAU/SVXLink_Git/refs/heads/main/RPI_Status_OLED/oled_sh1106.py" \
  -o "$TARGET"

chmod +x "$TARGET"
chown "$RUN_AS:$RUN_AS" "$TARGET" || true

cat >/etc/systemd/system/oled-sh1106.service <<EOF
[Unit]
Description=SH1106 OLED Display
After=multi-user.target

[Service]
Type=simple
User=$RUN_AS
ExecStart=$VENV_DIR/bin/python $TARGET
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now oled-sh1106.service
