#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONS_DIR="$HOME/.local/share/applications"

# Stage 22 publishes one simple control-center entry in the application menu.
# Website and Background remain available inside My Desktop Settings, so remove
# the older stand-alone menu entries before any live-desktop reinstall guard can
# stop the rest of this script. This keeps menu cleanup reliable even when the
# GrayHaired Live Desktop DING process is already running.
mkdir -p "$APPLICATIONS_DIR"
rm -f \
    "$APPLICATIONS_DIR/grayhaired-live-desktop-website.desktop" \
    "$APPLICATIONS_DIR/grayhaired-live-desktop-background.desktop"

# Build the proven GNOME X11/Wayland live-desktop geometry and WebKit surface.
bash "$SCRIPT_DIR/install-wayland-separate-ding-prototype.sh" "$@"

# Add the promoted Automatic Blend appearance chain, including photographic
# continuation through the scrollable icon canvas.
bash "$SCRIPT_DIR/patch-live-desktop-automatic-blend-promoted.sh"

# Keep the physically verified Stage 15 adaptive vertical icon scrolling.
bash "$SCRIPT_DIR/patch-live-desktop-virtual-scroll-canvas-stage15.sh"

# Stage 17 adds the physically verified user-selectable Manual Background
# override while preserving Automatic Blend as the default/fallback behavior.
bash "$SCRIPT_DIR/patch-live-desktop-manual-background-stage17.sh"

# Stage 18 is the physically verified tighter icon-pane geometry. Tiny and
# Small use a 204px minimum, avoiding the accidental three-column Tiny grid
# while returning more horizontal space to the live webpage.
bash "$SCRIPT_DIR/patch-live-desktop-tight-width-stage18.sh"

# Stage 19 prevents an accidental local file drop from navigating WebKit away
# from the configured desktop website. Normal HTTP/HTTPS navigation and DING
# desktop-icon dragging remain unchanged.
bash "$SCRIPT_DIR/patch-live-desktop-block-local-file-drop-stage19.sh"

# Stage 20 adds physically verified modern-site link handling: explicit
# user-gesture HTTP(S) create requests open in the default browser, and the
# interactive MSN/Microsoft sign-in flow is handed off narrowly while silent
# background account probes remain embedded in WebKit.
bash "$SCRIPT_DIR/patch-live-desktop-modern-site-links-stage20.sh"

# Stage 21 replaces the hard-coded startup URL with a persistent user setting.
# The GTK 4 selector supports presets plus arbitrary HTTP(S) websites and keeps
# the choice under ~/.config/grayhaired-live-desktop/site.json.
bash "$SCRIPT_DIR/patch-live-desktop-website-config-stage21.sh"

# Install/refresh the one consolidated Stage 22 application-menu entry.
bash "$SCRIPT_DIR/install-live-desktop-settings-launcher.sh"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

printf '\n[GRAYHAIRED-INSTALL] PASS: GrayHaired Live Desktop with Automatic Blend, Manual Background, 204px compact icon geometry, adaptive vertical scrolling, local-file drop protection, modern-site browser handoff, persistent website selection, and the consolidated My Desktop Settings control center installed.\n'
printf '[GRAYHAIRED-INSTALL] INFO: run scripts/verify-live-desktop-known-good.sh after enabling the extension.\n'
