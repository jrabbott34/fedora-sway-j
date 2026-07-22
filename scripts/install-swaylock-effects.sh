#!/usr/bin/env bash
# Builds swaylock-effects (ErikReider/swaylock-effects -- the actively
# maintained fork; the original mortie/swaylock-effects is unmaintained)
# from source.
#
# There IS a COPR for this (pheeef/swaylock-effects), but its RPM installs
# to /usr/bin/swaylock -- the exact same path as Fedora's own swaylock
# package, with no Provides/Obsoletes to cleanly replace it -- which risks
# a file conflict, and unlike sway/SwayFX there'd be no separate vanilla
# fallback binary if something went wrong. A broken lock screen (stuck
# locked out) is a much worse failure mode than a broken compositor, so
# this builds to /usr/local instead, same pattern as SwayFX: Fedora's own
# /usr/bin/swaylock stays untouched as a guaranteed-working fallback.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

echo "==> Installing build deps..."
sudo dnf -y install \
  meson pkgconf-pkg-config gcc scdoc \
  wayland-devel wayland-protocols-devel libxkbcommon-devel \
  cairo-devel gdk-pixbuf2-devel pam-devel

BUILD_DIR="$HOME/build/swaylock-effects"
rm -rf "$BUILD_DIR"
git clone https://github.com/ErikReider/swaylock-effects.git "$BUILD_DIR"

(
  cd "$BUILD_DIR"
  meson setup build --prefix=/usr/local
  ninja -C build
  sudo ninja -C build install
)

cat <<'EOF'

==> Done. /usr/local/bin/swaylock now takes priority over Fedora's vanilla
    /usr/bin/swaylock (dnf-installed) via PATH -- that stays untouched as
    a guaranteed fallback (call it by full path if this one ever misbehaves).

Verify with:
    hash -r; swaylock --version

IMPORTANT: test it directly before trusting it for real. Run `swaylock`
from a terminal, confirm the blurred-screenshot lock screen renders and
that you can actually type your password and unlock successfully -- a
lock screen that fails while your session is genuinely locked is a much
worse spot to be in than a compositor that fails to start. Only after
confirming that should you rely on it via swayidle/mod+ctrl+l (dotfiles
already reference plain `swaylock`, so no config changes are needed once
this is installed).
EOF
