#!/usr/bin/env bash
# Installs SDDM with the Sugar Candy theme, replacing GDM as the display
# manager. Sugar Candy itself isn't packaged for Fedora, so it's cloned
# from the actively-maintained fork (the original MarianArlt/sddm-sugar-candy
# is unmaintained).
#
# Fedora's sddm is built against Qt6, which dropped the QtGraphicalEffects
# QML module Sugar Candy imports (Qt5-only). The Qt6 replacement is
# Qt5Compat.GraphicalEffects (from qt6-qt5compat), so the theme's .qml
# files get patched to import that instead of installing a Qt5 runtime
# sddm would never actually use.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

THEME_REPO="${THEME_REPO:-https://github.com/Kangie/sddm-sugar-candy.git}"
THEME_DIR="/usr/share/sddm/themes/sugar-candy"

echo "==> Installing sddm and the Qt6 QML deps the theme needs..."
sudo dnf -y install sddm qt6-qt5compat qt6-qtsvg qt6-qtdeclarative

echo "==> Switching display manager: gdm -> sddm..."
sudo systemctl disable --now gdm.service 2>/dev/null || true
sudo systemctl enable sddm.service

# Fedora Server defaults to multi-user.target (text-mode boot). Without
# this, sddm.service is "enabled" but never actually starts at boot, and
# you land on a plain TTY login instead of the SDDM screen.
sudo systemctl set-default graphical.target

echo "==> Installing Sugar Candy theme from ${THEME_REPO}..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 "$THEME_REPO" "$TMP_DIR/sddm-sugar-candy"
sudo rm -rf "$THEME_DIR"
sudo cp -r "$TMP_DIR/sddm-sugar-candy" "$THEME_DIR"
rm -rf "$TMP_DIR"

echo "==> Patching theme QML for Qt6 (QtGraphicalEffects -> Qt5Compat.GraphicalEffects)..."
sudo find "$THEME_DIR" -name '*.qml' -exec \
  sed -i -E 's/^import QtGraphicalEffects[[:space:]0-9.]*/import Qt5Compat.GraphicalEffects/' {} +

echo "==> Setting Sugar Candy as the active SDDM theme..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'EOF'
[Theme]
Current=sugar-candy
EOF

echo
echo "==> Done. Switching to graphical.target now (no reboot needed)..."
sudo systemctl isolate graphical.target

echo "    Theme config/background/customization: ${THEME_DIR}/theme.conf.user"
echo "    (copy theme.conf to theme.conf.user before editing -- see the theme's README)"
