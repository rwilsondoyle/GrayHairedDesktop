#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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

# Publish a normal Zorin application-menu entry for the friendly GTK 4 settings
# window so users do not need to know or run helper commands.
bash "$SCRIPT_DIR/install-live-desktop-background-launcher.sh"

printf '\n[GRAYHAIRED-INSTALL] PASS: GrayHaired Live Desktop with Automatic Blend, Manual Background, 204px compact icon geometry, adaptive vertical scrolling, local-file drop protection, and modern-site browser handoff installed.\n'
printf '[GRAYHAIRED-INSTALL] INFO: run scripts/verify-live-desktop-known-good.sh after enabling the extension.\n'
