#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
RESTORE="$SCRIPT_DIR/restore-live-desktop-wallpaper-stage6.sh"
BG_LAUNCHER="$HOME/.local/share/applications/grayhaired-live-desktop-background.desktop"

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
# photographic-page paths.
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
require_grid_text "GRAYHAIRED-COMPRESSED-WIDTH-STAGE11" "compressed icon-pane width Stage 11 foundation is present"

# Stage 15 adaptive vertical icon scrolling.
require_grid_text "GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15" "virtual scrolling icon canvas Stage 15 is present"
require_grid_text "vscrollbar_policy: Gtk.PolicyType.AUTOMATIC" "automatic vertical scrollbar policy is present"
require_grid_text "_grayhairedScrollableItemCount()" "Stage 15 desktop and special-icon counter is present"
require_grid_text "this._container.set_size_request(-1, this._height);" "Stage 15 virtual canvas height request is present"
require_grid_text "[GRAYHAIRED-SCROLL15] items=" "Stage 15 scrolling diagnostics are present"

# Stage 16 photographic continuation across the taller Stage-15 icon canvas.
require_grid_text "GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16" "photo continuation across scroll canvas Stage 16 is present"
require_grid_text "_livePhotoCanvasStyleContext" "Stage 16 photo style is applied to the virtual icon canvas"
require_grid_text "background-repeat: repeat-y" "Stage 16 vertical photo continuation rule is present"
require_grid_text "[GRAYHAIRED-PHOTO16] canvas=" "Stage 16 photo-scroll diagnostics are present"

# Stage 17 user-selectable manual background. Automatic Blend remains the
# default when the user config file is absent, invalid, or set to automatic.
require_grid_text "GRAYHAIRED-MANUAL-BACKGROUND-STAGE17" "manual background override Stage 17 is present"
require_grid_text "_grayhairedBackgroundPreference" "Stage 17 preference reader is present"
require_grid_text "[GRAYHAIRED-MANUAL17] applied color=" "Stage 17 manual-color logging is present"
require_grid_text "[GRAYHAIRED-MANUAL17] photo override color=" "Stage 17 photographic override logging is present"
[[ -f "$SCRIPT_DIR/live-desktop-background-settings.py" ]] || fail "GTK background settings UI is missing"
pass "GTK background settings UI is present"
[[ -f "$SCRIPT_DIR/open-live-desktop-background-settings.sh" ]] || fail "background settings launcher helper is missing"
pass "background settings launcher helper is present"
[[ -f "$BG_LAUNCHER" ]] || fail "Zorin application-menu background launcher is missing"
grep -Fq 'Name=My Desktop Background' "$BG_LAUNCHER" || fail "background app-menu launcher name is incorrect"
pass "Zorin application-menu entry for My Desktop Background is present"

# Stage 18 replaces the old 240px Stage-11 floor with the physically verified
# 204px minimum. Tiny/Small stay at two columns and the WebKit page receives
# more horizontal room.
require_grid_text "GRAYHAIRED-TIGHT-WIDTH-STAGE18" "tight icon-pane width Stage 18 is present"
[[ "$(grep -Fc 'const liveIconStripMin = 204;' "$GRID")" -ge 2 ]] || fail "204px minimum is not present in both startup and live-reflow geometry"
pass "204px minimum is present in startup and live-reflow geometry"
require_grid_text "min=204px" "Stage 18 204px geometry diagnostics are present"
forbid_grid_text "const liveIconStripMin = 240;" "obsolete 240px minimum is absent"

# Stage 19 rejects file:// navigation requests so an accidental local-file drop
# cannot replace the configured desktop website inside WebKit.
require_grid_text "GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19" "local-file drop/navigation guard Stage 19 is present"
require_grid_text "uri.startsWith('file://')" "Stage 19 file URI rejection is present"
require_grid_text "[GRAYHAIRED-DROP19] blocked local file navigation:" "Stage 19 blocked-drop diagnostics are present"

# Stage 20 modern-site link handling. Physically verified with MSN: ordinary
# JavaScript/new-window card links open in the default browser, and explicit
# Microsoft sign-in is handed off while silent prompt=none probes stay embedded.
require_grid_text "GRAYHAIRED-MODERN-SITE-LINKS-STAGE20" "modern-site create handoff Stage 20 is present"
require_grid_text "navigationAction.is_user_gesture()" "Stage 20 user-gesture check is present"
require_grid_text "uri.startsWith('https://') || uri.startsWith('http://')" "Stage 20 HTTP(S)-only create handoff is present"
require_grid_text "[GRAYHAIRED-LINK20] handoff browser uri=" "Stage 20 browser-handoff logging is present"
require_grid_text "GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20" "Stage 20 narrow Microsoft-auth handoff is present"
require_grid_text "uri.includes('prompt=select_account')" "Stage 20 interactive Microsoft-auth selector is present"
require_grid_text "[GRAYHAIRED-LINK20] handoff Microsoft sign-in uri=" "Stage 20 Microsoft-auth handoff logging is present"

# Diagnostic-only test scaffolding should not be part of a clean promoted install.
forbid_grid_text "GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20" "Stage 20 create diagnostic scaffold is absent"
forbid_grid_text "GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B" "Stage 20B navigation diagnostic scaffold is absent"
forbid_grid_text "GRAYHAIRED-CREATE-HANDOFF-STAGE20" "Stage 20 test create-handoff marker is absent"
forbid_grid_text "GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20C" "Stage 20C test auth marker is absent"

# Failed/superseded experiments do not belong in known-good.
forbid_grid_text "GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8" "failed Stage 8 arbitrary-link experiment is absent"
forbid_grid_text "GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10" "failed Stage 10 scrolling-pane experiment is absent"
forbid_grid_text "GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12" "superseded Stage 12 row-density experiment is absent"
forbid_grid_text "GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E" "failed Stage 13E overlay experiment is absent"
forbid_grid_text "GRAYHAIRED-VERTICAL-SCROLL-STAGE14" "superseded Stage 14 scrollbar-only experiment is absent"

pass "promoted live desktop is configured with Stage 15 scrolling, Stage 16 photo continuation, Stage 17 background controls, Stage 18 compact 204px width, Stage 19 local-file drop protection, and Stage 20 modern-site browser handoff"
