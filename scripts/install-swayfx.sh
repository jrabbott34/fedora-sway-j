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
  mesa-libGLES-devel systemd-devel libevdev-devel hwdata
)
sudo dnf -y install "${DEPS[@]}"

# Fedora's hwdata package ships the pnp.ids data file wlroots' DRM backend
# needs, but doesn't ship a pkg-config file for it -- so wlroots' build-time
# `dependency('hwdata')` check silently fails and it disables the DRM
# backend entirely (a *build* succeeds either way, but the resulting sway
# binary can't start on real hardware, only nested-in-X11). Registering a
# minimal .pc file ourselves fixes this without patching wlroots.
if ! pkg-config --exists hwdata 2>/dev/null; then
  echo "==> Registering a pkg-config file for hwdata (needed for DRM backend support)..."
  cat <<'EOF' | sudo tee /usr/share/pkgconfig/hwdata.pc > /dev/null
prefix=/usr
pkgdatadir=${prefix}/share/hwdata

Name: hwdata
Description: Hardware identification and configuration data
Version: 1
EOF
fi

# If a previous run already installed wlroots/scenefx .pc files, meson will
# find those via plain pkg-config on this run and never rebuild from the
# (now hwdata-fixed) subproject source -- then error trying to also resolve
# the top-level project's own subproject reference to the same dependency
# name ("Tried to override dependency ... which has already been resolved").
# Clearing any previously installed copies avoids that entirely.
echo "==> Clearing any previously installed wlroots/scenefx build artifacts..."
sudo rm -f /usr/local/lib64/libwlroots-0.19.so /usr/local/lib64/libscenefx-0.4.so
sudo rm -f /usr/local/lib64/pkgconfig/wlroots-0.19.pc /usr/local/lib64/pkgconfig/scenefx-0.4.pc
sudo rm -rf /usr/local/include/wlroots-0.19 /usr/local/include/scenefx-0.4
sudo ldconfig

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
echo "    Fedora's GCC/C23 combo is newer than what wlroots 0.19.0 was written"
echo "    against -- e.g. it treats an unhandled newer libinput enum value and"
echo "    a strchr() const-qualifier mismatch as hard errors via -Werror,"
echo "    even though the pinned wlroots/scenefx combo is otherwise correct."
echo "    CFLAGS=-Wno-error downgrades those back to non-fatal warnings."
(
  cd "$BUILD_DIR"
  CFLAGS="-Wno-error" meson setup build --prefix=/usr/local
  ninja -C build
  sudo ninja -C build install
  sudo ldconfig
)

echo "==> Registering /usr/local/lib64 with the dynamic linker..."
echo "    (libscenefx/libwlroots land there, but it's not searched by default"
echo "    on Fedora even after ldconfig, unless explicitly registered)"
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/local-swayfx.conf > /dev/null
sudo ldconfig

echo "==> Disambiguating the SDDM/GDM session entry from vanilla Sway's..."
SESSION_DESKTOP="/usr/local/share/wayland-sessions/sway.desktop"
if [[ -f "$SESSION_DESKTOP" ]]; then
  sudo sed -i 's/^Name=.*/Name=SwayFX/' "$SESSION_DESKTOP"
fi

echo
echo "==> Done. 'sway --version' only tells you what a fresh invocation would"
echo "    be -- it does NOT confirm the compositor actually starts. If you're"
echo "    at this terminal from a TTY (no session running), the most direct"
echo "    test is to just run 'sway' right now and see if it takes over the"
echo "    screen. If you're inside an already-running session instead, log"
echo "    out completely and back in (a live compositor process won't pick"
echo "    up a newly installed binary until it's restarted)."
echo
echo "==> Kept intact as a fallback: /usr/bin/sway (Fedora's vanilla dnf package)."
echo "    If SwayFX ever fails to start, switch to a TTY (Ctrl+Alt+F3) and run"
echo "    /usr/bin/sway directly to get back into a known-working session."
echo "    At the SDDM/GDM login screen, look for a 'SwayFX' session entry"
echo "    (renamed above) distinct from the plain 'Sway' one."
echo
echo "==> Once confirmed working, uncomment the blur/corner_radius/shadow/"
echo "    default_dim_inactive lines in dotfiles/.config/sway/config -- they"
echo "    were commented out earlier because vanilla Sway doesn't support them."
