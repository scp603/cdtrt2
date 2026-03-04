#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_DIR="${HOME}/.config/systemd/user"

mkdir -p "$UNIT_DIR"

cp "$SCRIPT_DIR/python2-certbot.service" "$UNIT_DIR/"
cp "$SCRIPT_DIR/python2-certbot.timer" "$UNIT_DIR/"

systemctl --user daemon-reload
systemctl --user enable --now python2-certbot.timer

echo "python2-certbot.timer deployed and running"
systemctl --user status python2-certbot.timer --no-pager
