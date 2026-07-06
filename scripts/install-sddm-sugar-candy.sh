#!/usr/bin/env bash
# Installs SDDM with the Sugar Candy theme, replacing GDM as the display
# manager. Sugar Candy itself isn't packaged for Fedora, so it's cloned
# from the actively-maintained fork (the original MarianArlt/sddm-sugar-candy
# is unmaintained).
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

THEME_REPO="${THEME_REPO:-https://github.com/Kangie/sddm-sugar-candy.git}"
THEME_DIR="/usr/share/sddm/themes/sugar-candy"

echo "==> Installing sddm and Qt5 QML deps the theme needs..."
sudo dnf -y install sddm qt5-qtgraphicaleffects qt5-qtquickcontrols2 qt5-qtsvg

echo "==> Switching display manager: gdm -> sddm..."
sudo systemctl disable --now gdm.service 2>/dev/null || true
sudo systemctl enable sddm.service

echo "==> Installing Sugar Candy theme from ${THEME_REPO}..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 "$THEME_REPO" "$TMP_DIR/sddm-sugar-candy"
sudo rm -rf "$THEME_DIR"
sudo cp -r "$TMP_DIR/sddm-sugar-candy" "$THEME_DIR"
rm -rf "$TMP_DIR"

echo "==> Setting Sugar Candy as the active SDDM theme..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'EOF'
[Theme]
Current=sugar-candy
EOF

echo
echo "==> Done. Reboot (or switch to a TTY and back) to see SDDM with Sugar Candy."
echo "    Theme config/background/customization: ${THEME_DIR}/theme.conf.user"
echo "    (copy theme.conf to theme.conf.user before editing -- see the theme's README)"
