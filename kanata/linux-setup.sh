#!/usr/bin/env bash
# Install kanata on Arch/Omarchy and run kanata.kbd as a systemd user service.
# Lets kanata run unprivileged: the user joins `input` (read keyboards) and
# `uinput` (create the virtual output keyboard).
set -euo pipefail

cfg="$(cd "$(dirname "$0")" && pwd)/kanata.kbd"

command -v kanata >/dev/null || yay -S --needed kanata-bin

sudo groupadd -f uinput
sudo usermod -aG input,uinput "$USER"
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
  sudo tee /etc/udev/rules.d/99-uinput.rules >/dev/null
echo uinput | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
sudo modprobe uinput
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=uinput

mkdir -p ~/.config/systemd/user
cat >~/.config/systemd/user/kanata.service <<EOF
[Unit]
Description=kanata keyboard remapper

[Service]
ExecStart=$(command -v kanata) --cfg $cfg
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable kanata.service

echo "Done. Log out and back in (for the new groups), then kanata starts automatically."
echo "Or test now without relogging:  sudo kanata --cfg $cfg"
