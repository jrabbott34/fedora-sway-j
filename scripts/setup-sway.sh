#!/usr/bin/env bash
# Post-install setup: run inside a fresh Fedora Server install to bring up
# a minimal Sway session, no GNOME/DE baggage.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

sudo dnf -y upgrade

# Core Sway session + Wayland portals
sudo dnf -y install \
  sway swaylock swayidle swaybg \
  waybar \
  foot \
  wofi \
  xdg-desktop-portal-wlr \
  polkit \
  NetworkManager-tui \
  pipewire pipewire-pulseaudio wireplumber \
  brightnessctl playerctl \
  grim slurp wl-clipboard \
  mesa-dri-drivers mesa-vulkan-drivers \
  setroubleshoot-server policycoreutils-python-utils

# audit2allow / setroubleshoot are included above so SELinux denials from
# Sway/Waybar/etc. can be diagnosed with `sudo ausearch -m avc -ts recent`
# and `audit2allow` rather than guessing.

echo
echo "Base Sway session installed."
echo "Log in and start Sway with: sway"
echo "If it fails to start under 3D accel, retry with: WLR_RENDERER=pixman sway"
