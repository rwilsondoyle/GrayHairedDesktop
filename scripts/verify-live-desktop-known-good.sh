#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
RESTORE="$SCRIPT_DIR/restore-live-desktop-wallpaper-stage6.sh"

# First run the proven geometry/WebKit/runtime verifier.
bash "$SCRIPT_DIR/verify-wayland-known-good.sh" "$@"

pass() { printf '[GRAYHAIRED-VERIFY] PASS: %s\n' "$*"; }
fail() { printf '[GRAYHAIRED-VERIFY] FAIL: %s\n' "$*" >&2; exit 1; }
require_grid_text() {
    local text="$1"
    local description="$2"
    grep -Fq -- "$text" "$GRID" || fail "$description"
    pass "$description"
}
forbid_grid_text() {
    local text="$1"
    local description="$2"
    if grep -Fq -- "$text" "$GRID"; then
        fail "$description"
    fi
    pass "$description"
}

[[ -f "$GRID" ]] || fail "desktopGrid.js is missing: $GRID"
[[ -f "$RESTORE" ]] || fail "GNOME wallpaper restore helper is missing: $RESTORE"
pass "GNOME wallpaper restore helper is present"

# Promoted Automatic Blend combines the exact physically tested solid-page and
# photographic-page paths. A solid page uses sampled CSS color for both the
# icon pane and the real GNOME background beneath translucent shell surfaces.
# A page with a BODY background image uses the currently active image, caches
# it locally, paints it behind DING, synchronizes GNOME wallpaper, and reflows
# the photo whenever live icon-strip geometry changes.
require_grid_text "GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER" "Automatic Blend edge sampler is present"
require_grid_text "GRAYHAIRED-AUTOMATIC-BLEND-STAGE2" "solid-page sampled-color blend is present"
require_grid_text "confidence < 0.60" "solid-page blend confidence fallback is present"
require_grid_text "GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9" "solid-page GNOME background synchronization is present"
require_grid_text "[GRAYHAIRED-SOLID9] synced" "solid-page GNOME background synchronization logging is present"
require_grid_text "GRAYHAIRED-PHOTO-CONTINUATION-STAGE3" "photographic-page continuation is present"
require_grid_text "livePhotoDiscoveryScript" "active photographic background discovery is present"
require_grid_text "GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5" "photographic local curl cache is present"
require_grid_text "GRAYHAIRED-PHOTO-URL-CLEANUP-STAGE5C" "photographic URL cleanup is present"
require_grid_text "[GRAYHAIRED-PHOTO5] cached/applied" "photographic cache/apply logging is present"
require_grid_text "GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6" "GNOME wallpaper synchronization is present"
require_grid_text "[GRAYHAIRED-WALLPAPER6] synced" "GNOME wallpaper synchronization logging is present"
require_grid_text "GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7" "live photographic geometry reflow is present"
require_grid_text "size-allocate" "live photographic reflow allocation hook is present"
require_grid_text "[GRAYHAIRED-PHOTO7] reflow" "live photographic reflow logging is present"

# Stage 8 made navigation on a complex arbitrary site less reliable in physical
# testing and must not be part of the promoted known-good installation.
forbid_grid_text "GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8" "failed Stage 8 arbitrary-link experiment is absent"

pass "promoted Automatic Blend is configured for solid and photographic pages with live icon-size reflow"
