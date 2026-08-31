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

# Stage 17 adds the user-selectable Manual Background override while preserving
# Automatic Blend as the default/fallback behavior.
bash "$SCRIPT_DIR/patch-live-desktop-manual-background-stage17.sh"

# Publish a normal Zorin application-menu entry for the friendly GTK 4 settings
# window so users do not need to know or run helper commands.
bash "$SCRIPT_DIR/install-live-desktop-background-launcher.sh"

printf '\n[GRAYHAIRED-INSTALL] PASS: GrayHaired Live Desktop with Automatic Blend, Manual Background, and adaptive vertical icon scrolling installed.\n'
printf '[GRAYHAIRED-INSTALL] INFO: run scripts/verify-live-desktop-known-good.sh after enabling the extension.\n'
