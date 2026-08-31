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
require_grid_text "GRAYHAIRED-COMPRESSED-WIDTH-STAGE11" "compressed icon-pane width Stage 11 is present"
require_grid_text "const liveIconStripMin = 240;" "compressed icon-pane minimum width is present"

# Stage 15 is the physically verified vertical-overflow design. It preserves
# the Stage 11 horizontal split and grows only the internal DING icon canvas,
# allowing the existing ScrolledWindow to expose a normal vertical scrollbar
# when required. Physical testing passed Tiny, Small, Standard, and Large.
require_grid_text "GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15" "virtual scrolling icon canvas Stage 15 is present"
require_grid_text "vscrollbar_policy: Gtk.PolicyType.AUTOMATIC" "automatic vertical scrollbar policy is present"
require_grid_text "_grayhairedScrollableItemCount()" "Stage 15 desktop and special-icon counter is present"
require_grid_text "this._container.set_size_request(-1, this._height);" "Stage 15 virtual canvas height request is present"
require_grid_text "[GRAYHAIRED-SCROLL15] items=" "Stage 15 scrolling diagnostics are present"

# Stage 16 extends the active photographic continuation across the taller
# Stage-15 icon canvas. It keeps the visible crop aligned with WebKit while
# vertically repeating that same crop only in the off-screen overflow region.
require_grid_text "GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16" "photo continuation across scroll canvas Stage 16 is present"
require_grid_text "_livePhotoCanvasStyleContext" "Stage 16 photo style is applied to the virtual icon canvas"
require_grid_text "background-repeat: repeat-y" "Stage 16 vertical photo continuation rule is present"
require_grid_text "[GRAYHAIRED-PHOTO16] canvas=" "Stage 16 photo-scroll diagnostics are present"

# Failed/superseded experiments do not belong in known-good.
forbid_grid_text "GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8" "failed Stage 8 arbitrary-link experiment is absent"
forbid_grid_text "GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10" "failed Stage 10 scrolling-pane experiment is absent"
forbid_grid_text "GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12" "superseded Stage 12 row-density experiment is absent"
forbid_grid_text "GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E" "failed Stage 13E overlay experiment is absent"
forbid_grid_text "GRAYHAIRED-VERTICAL-SCROLL-STAGE14" "superseded Stage 14 scrollbar-only experiment is absent"

pass "promoted Automatic Blend is configured with Stage 11 compressed width, Stage 15 adaptive vertical scrolling, and Stage 16 photographic scroll continuation"
