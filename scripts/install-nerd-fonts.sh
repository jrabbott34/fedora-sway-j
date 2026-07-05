#!/usr/bin/env bash
# Installs FiraCode Nerd Font for the current user. Fedora doesn't package
# Nerd Fonts, but every dotfile in this repo (Waybar, wofi, foot, alacritty,
# dunst, swaync, wlogout, GTK) references "FiraCode Nerd Font" by name, so
# without this the icon glyphs (workspace icons, module icons, etc.) are
# just missing and everything falls back to plain monospace.
set -euo pipefail

VERSION="${NERD_FONTS_VERSION:-v3.2.1}"
FONT_DIR="$HOME/.local/share/fonts/FiraCodeNerdFont"
TMP_ZIP="$(mktemp --suffix=.zip)"

mkdir -p "$FONT_DIR"

echo "==> Downloading FiraCode Nerd Font ${VERSION}..."
curl -fL -o "$TMP_ZIP" \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/FiraCode.zip"

echo "==> Extracting..."
unzip -o -q "$TMP_ZIP" -d "$FONT_DIR"
rm -f "$TMP_ZIP"

echo "==> Rebuilding font cache..."
fc-cache -f "$FONT_DIR" >/dev/null

echo "==> Done. Verify with: fc-list | grep -i 'FiraCode Nerd Font'"
echo "    Restart Waybar/Sway (mod+Shift+r) to pick it up."
