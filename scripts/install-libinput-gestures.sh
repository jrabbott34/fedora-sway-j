#!/usr/bin/env bash
# Installs libinput-gestures straight from upstream (bulletmark/libinput-gestures)
# instead of via COPR -- COPR builds are pinned to specific Fedora release
# chroots and can lag behind your actual Fedora version (e.g. no fedora-44
# chroot yet on some COPR projects), while upstream's own installer just
# needs python3 + libinput (already present) and drops the script straight
# at /usr/bin/libinput-gestures, matching what
# dotfiles/.config/systemd/user/libinput-gestures.service hardcodes as
# ExecStart.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

echo "==> Installing xdotool/wmctrl (used by gesture actions)..."
sudo dnf -y install xdotool wmctrl

echo "==> Making sure \$USER is in the 'input' group (needed to read touchpad events)..."
sudo usermod -aG input "$USER"

echo "==> Cloning and installing libinput-gestures from upstream..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 https://github.com/bulletmark/libinput-gestures "$TMP_DIR/libinput-gestures"
(cd "$TMP_DIR/libinput-gestures" && sudo ./libinput-gestures-setup install)
rm -rf "$TMP_DIR"

echo "==> Reloading/starting the user service..."
systemctl --user daemon-reload
systemctl --user enable --now libinput-gestures.service

cat <<EOF

==> Done. Test gestures with: libinput-gestures-setup test
    (Ctrl+C to stop watching)

If gestures still don't fire, you likely need to log out and back in for
the 'input' group membership to take effect in this session -- check with:
    groups | grep input
EOF
