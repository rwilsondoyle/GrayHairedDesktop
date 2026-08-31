#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Build the proven GNOME X11/Wayland live-desktop geometry and WebKit surface.
bash "$SCRIPT_DIR/install-wayland-separate-ding-prototype.sh" "$@"

# Then add the promoted appearance layer. This is intentionally applied only
# after the base installer has completed its own structural verification.
# Solid pages receive sampled-color blending; photographic pages automatically
# follow the currently active BODY background image, including rotating images.
bash "$SCRIPT_DIR/patch-live-desktop-automatic-blend-promoted.sh"

# Finally add the physically verified Stage 15 vertical overflow behavior.
# DING keeps the Stage 11 horizontal pane geometry, but its internal Gtk.Fixed
# canvas grows vertically when the current Desktop items need more rows than
# fit on screen. The existing Gtk.ScrolledWindow then exposes a normal vertical
# scrollbar only when required. This was physically verified across Tiny,
# Small, Standard, and Large icon sizes on the 1366x768 Wayland test system.
bash "$SCRIPT_DIR/patch-live-desktop-virtual-scroll-canvas-stage15.sh"

printf '\n[GRAYHAIRED-INSTALL] PASS: GrayHaired Live Desktop with Automatic Blend and adaptive vertical icon scrolling installed.\n'
printf '[GRAYHAIRED-INSTALL] INFO: run scripts/verify-live-desktop-known-good.sh after enabling the extension.\n'
