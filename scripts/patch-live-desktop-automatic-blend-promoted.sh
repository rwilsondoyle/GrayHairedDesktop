#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

printf '[GRAYHAIRED-BLEND] Installing promoted Automatic Blend support.\n'
printf '[GRAYHAIRED-BLEND] Solid pages use sampled color; photographic pages use the active page photo.\n'

# Apply the exact physically tested chain without reloading between steps.
# Earlier experimental names are retained as implementation history, but the
# supported entry point is this single promoted script.
bash "$SCRIPT_DIR/patch-live-desktop-blend-sampler.sh"
bash "$SCRIPT_DIR/patch-live-desktop-automatic-blend-stage2.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-background-diagnostic.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-continuation-stage3.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-local-cache-stage4.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-curl-cache-stage5.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-url-cleanup-stage5c.sh"
bash "$SCRIPT_DIR/patch-live-desktop-wallpaper-sync-stage6.sh"
bash "$SCRIPT_DIR/patch-live-desktop-photo-live-reflow-stage7.sh"
bash "$SCRIPT_DIR/patch-live-desktop-solid-wallpaper-sync-stage9.sh"
bash "$SCRIPT_DIR/patch-live-desktop-compressed-width-stage11.sh"

printf '[GRAYHAIRED-BLEND] PASS: promoted Automatic Blend chain installed.\n'
printf '[GRAYHAIRED-BLEND] INFO: solid pages use sampled color for both icon pane and translucent-shell backing.\n'
printf '[GRAYHAIRED-BLEND] INFO: photographic pages follow static or rotating BODY backgrounds.\n'
printf '[GRAYHAIRED-BLEND] INFO: icon-pane width uses the physically tested compressed range: Tiny/Small=240px, Standard=264px, Large=284px.\n'
printf '[GRAYHAIRED-BLEND] INFO: photographic alignment follows live Tiny/Small/Standard/Large icon-strip reflow without reloads.\n'
printf '[GRAYHAIRED-BLEND] INFO: original GNOME wallpaper can be restored with scripts/restore-live-desktop-wallpaper-stage6.sh\n'
