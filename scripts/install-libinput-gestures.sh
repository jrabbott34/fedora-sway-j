#!/usr/bin/env bash
# Installs libinput-gestures via COPR. Not in Fedora's official repos, and
# unlike a pip/pipx install, COPR's RPM puts the binary at /usr/bin, which
# is what dotfiles/.config/systemd/user/libinput-gestures.service hardcodes
# as ExecStart -- so this is the install path that actually matches the
# service file already deployed by deploy-configs.sh.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

echo "==> Enabling COPR and installing libinput-gestures..."
sudo dnf -y copr enable galaticstryder/libinput-gestures
sudo dnf -y install libinput-gestures xdotool wmctrl

echo "==> Making sure \$USER is in the 'input' group (needed to read touchpad events)..."
sudo usermod -aG input "$USER"

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
