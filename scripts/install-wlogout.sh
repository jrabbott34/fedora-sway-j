#!/usr/bin/env bash
# Builds wlogout from source (ArtsyMacaw/wlogout). Not packaged for Fedora
# and no COPR was found for it, but it's a small GTK3 + gtk-layer-shell C
# project (meson/ninja build), so building it directly is straightforward
# and doesn't depend on any COPR chroot existing for your Fedora release.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

echo "==> Installing build deps..."
sudo dnf -y install meson ninja-build gcc gtk3-devel \
  gobject-introspection-devel gtk-layer-shell-devel scdoc systemd-devel

echo "==> Cloning and building wlogout..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 https://github.com/ArtsyMacaw/wlogout.git "$TMP_DIR/wlogout"
(
  cd "$TMP_DIR/wlogout"
  meson setup build --prefix=/usr
  ninja -C build
  sudo ninja -C build install
)
rm -rf "$TMP_DIR"

echo
echo "==> Done. Test it directly with: wlogout -b 3 -c 20 -r 20"
echo "    (matches the invocation used in the sway keybind / swipe-down gesture)"
