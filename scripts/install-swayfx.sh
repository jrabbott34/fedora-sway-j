#!/usr/bin/env bash
# Builds SwayFX (WillPower3309/swayfx) from source, pinned to the versions
# upstream documents as tested together: SwayFX 0.5.3, SceneFX 0.4.1,
# wlroots 0.19.0. wlroots' API isn't stable across versions, so these are
# built as meson subprojects rather than linking Fedora's system wlroots
# package, which may not match.
#
# Installs to /usr/local (not /usr), so it never touches or overwrites
# Fedora's dnf-managed vanilla `sway` package at /usr/bin/sway. Since
# /usr/local/bin comes before /usr/bin in PATH, running `sway` after this
# runs SwayFX -- but /usr/bin/sway remains untouched as a guaranteed-working
# fallback if SwayFX ever fails to start (switch to a TTY and run
# /usr/bin/sway directly).
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

SWAYFX_TAG="${SWAYFX_TAG:-0.5.3}"
SCENEFX_TAG="${SCENEFX_TAG:-0.4.1}"
WLROOTS_TAG="${WLROOTS_TAG:-0.19.0}"

echo "==> Installing build deps..."
DEPS=(
  meson pkgconf-pkg-config cmake scdoc
  wayland-protocols-devel wayland-devel pcre2-devel json-c-devel
  pango-devel cairo-devel gdk-pixbuf2-devel
  libdrm-devel mesa-libgbm-devel libinput-devel libseat-devel libxkbcommon-devel
  libxcb-devel xcb-util-devel xcb-util-wm-devel xcb-util-renderutil-devel
  libliftoff-devel libdisplay-info-devel lcms2-devel pixman-devel
  mesa-libGLES-devel systemd-devel libevdev-devel
)
sudo dnf -y install "${DEPS[@]}"

echo "==> Cloning SwayFX ${SWAYFX_TAG} + SceneFX ${SCENEFX_TAG} + wlroots ${WLROOTS_TAG}..."
echo "    (this is a much bigger clone/build than the other scripts -- expect several minutes)"
BUILD_DIR="$HOME/build/swayfx"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

git clone https://github.com/WillPower3309/swayfx.git "$BUILD_DIR"
(cd "$BUILD_DIR" && git checkout "$SWAYFX_TAG")

mkdir -p "$BUILD_DIR/subprojects"
git clone https://github.com/wlrfx/scenefx.git "$BUILD_DIR/subprojects/scenefx"
(cd "$BUILD_DIR/subprojects/scenefx" && git checkout "$SCENEFX_TAG")

git clone https://gitlab.freedesktop.org/wlroots/wlroots.git "$BUILD_DIR/subprojects/wlroots"
(cd "$BUILD_DIR/subprojects/wlroots" && git checkout "$WLROOTS_TAG")

echo "==> Building (meson + ninja)..."
(
  cd "$BUILD_DIR"
  meson setup build --prefix=/usr/local
  ninja -C build
  sudo ninja -C build install
  sudo ldconfig
)

echo
echo "==> Done. Verify with:"
echo "    sway --version"
echo "    Should report something like 'swayfx version ${SWAYFX_TAG}' (not vanilla sway)."
echo
echo "==> Kept intact as a fallback: /usr/bin/sway (Fedora's vanilla dnf package)."
echo "    If SwayFX ever fails to start, switch to a TTY (Ctrl+Alt+F3) and run"
echo "    /usr/bin/sway directly to get back into a known-working session."
echo
echo "==> Once confirmed working, uncomment the blur/corner_radius/shadow/"
echo "    default_dim_inactive lines in dotfiles/.config/sway/config -- they"
echo "    were commented out earlier because vanilla Sway doesn't support them."
