#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
APP="$EXT/app"
DING="$APP/ding.js"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS="$SCRIPT_DIR/wayland-layout-defaults.sh"
FILES_ONLY=false

if [[ "${1:-}" == "--files-only" ]]; then
    FILES_ONLY=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--files-only]" >&2
    exit 2
fi

pass() { printf '[GRAYHAIRED-VERIFY] PASS: %s\n' "$*"; }
fail() { printf '[GRAYHAIRED-VERIFY] FAIL: %s\n' "$*" >&2; exit 1; }
require_file_text() {
    local text="$1"
    local description="$2"
    grep -Fq -- "$text" "$GRID" || fail "$description"
    pass "$description"
}
forbid_file_text() {
    local text="$1"
    local description="$2"
    if grep -Fq -- "$text" "$GRID"; then
        fail "$description"
    fi
    pass "$description"
}

[[ -f "$DEFAULTS" ]] || fail "shared Wayland defaults are missing: $DEFAULTS"
# shellcheck source=/dev/null
source "$DEFAULTS"
[[ "${GRAYHAIRED_WAYLAND_DESKTOP_URL:-}" == https://* ]] || fail "Wayland desktop URL default is not HTTPS"
pass "shared Wayland layout defaults are present"

[[ -d "$EXT" ]] || fail "user-local GrayHaired extension is not installed: $EXT"
[[ -f "$GRID" ]] || fail "desktopGrid.js is missing: $GRID"
[[ -f "$DING" ]] || fail "ding.js is missing: $DING"
pass "user-local GrayHaired extension files exist"

require_file_text "imports.gi.versions.WebKit2 = '4.1';" "WebKit2 4.1 integration is present"

if grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID"; then
    for value_name in \
        GRAYHAIRED_WAYLAND_ICON_COLUMNS \
        GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING \
        GRAYHAIRED_WAYLAND_ICON_STRIP_MIN \
        GRAYHAIRED_WAYLAND_ICON_STRIP_MAX \
        GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK; do
        value="${!value_name:-}"
        [[ "$value" =~ ^[0-9]+$ ]] || fail "$value_name is invalid: ${value:-unset}"
    done
    [[ "$GRAYHAIRED_WAYLAND_ICON_COLUMNS" -ge 1 ]] || fail "adaptive icon column count is unexpectedly small"
    [[ "$GRAYHAIRED_WAYLAND_ICON_STRIP_MIN" -ge 100 ]] || fail "adaptive icon strip minimum is unexpectedly small"
    [[ "$GRAYHAIRED_WAYLAND_ICON_STRIP_MAX" -gt "$GRAYHAIRED_WAYLAND_ICON_STRIP_MIN" ]] || fail "adaptive icon strip maximum must exceed minimum"
    [[ "$GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK" -ge "$GRAYHAIRED_WAYLAND_ICON_STRIP_MIN" && "$GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK" -le "$GRAYHAIRED_WAYLAND_ICON_STRIP_MAX" ]] || fail "adaptive icon strip fallback is outside min/max range"
    pass "adaptive Wayland layout defaults are valid"

    require_file_text "Prefs.get_desired_width() + 4 * elementSpacing" "adaptive strip uses DING cell geometry"
    require_file_text "this._eventBox.set_size_request(liveIconStripWidth, -1);" "adaptive EventBox width is configured"
    require_file_text "[GRAYHAIRED-LAYOUT] icon cell=" "adaptive layout startup logging is present"
    pass "adaptive DING icon strip is configured"
else
    # Compatibility check for an older fixed-width installed tree. The current
    # shared defaults no longer expose a fixed-width variable, so verify the
    # physically tested 220px marker directly instead of referencing an unset
    # shell variable.
    require_file_text "const liveIconStripWidth = 220;" "legacy 220-pixel DING icon strip is configured"
    require_file_text "this._eventBox.set_size_request(220, -1);" "legacy fixed EventBox width is configured"
fi

require_file_text "this._liveSplitSurface = true;" "split-surface GTK allocation guard is present"
require_file_text "this._liveWebView = new WebKit2.WebView();" "live WebKit view is created"
require_file_text "$GRAYHAIRED_WAYLAND_DESKTOP_URL" "known-good My Desktop URL is configured"
require_file_text "[GRAYHAIRED-WEBKIT] Opening in default browser:" "external-link browser handoff is present"
require_file_text "The WebKit live-desktop surface and DING icon strip share this" "WebKit/DING keyboard-event guard is present"
require_file_text "this._liveWebView.has_focus" "WebKit focus test is present"
require_file_text "[GRAYHAIRED-WEBKIT] Live WebView created" "WebKit lifecycle creation logging is present"
require_file_text "[GRAYHAIRED-WEBKIT] Destroying live WebView" "WebKit lifecycle destruction logging is present"

forbid_file_text "Reclaim keyboard focus for DING when the icon strip is clicked" "experimental DING focus-reclaim marker is absent"
forbid_file_text "this._eventBox.grab_focus();" "experimental Gtk.EventBox grab_focus() is absent"
forbid_file_text "this._eventBox.set_can_focus(true);" "experimental Gtk.EventBox forced focus is absent"

if $FILES_ONLY; then
    pass "file-only verification complete"
    exit 0
fi

[[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] || fail "current session is not Wayland (found: ${XDG_SESSION_TYPE:-unknown})"
pass "current session is Wayland"

state="$(gnome-extensions info "$UUID" 2>/dev/null | awk -F': ' '/State:/ {print $2; exit}')"
[[ "$state" == "ACTIVE" ]] || fail "GrayHaired extension is not ACTIVE (state: ${state:-unknown})"
pass "GrayHaired GNOME extension is ACTIVE"

mapfile -t gray_pids < <(pgrep -f "gjs $DING -E -P $APP" 2>/dev/null || true)
(( ${#gray_pids[@]} == 1 )) || fail "expected exactly one GrayHaired DING/WebKit child, found ${#gray_pids[@]}: ${gray_pids[*]:-none}"
pass "exactly one GrayHaired DING/WebKit child is running (PID ${gray_pids[0]})"

if pgrep -f "/$SYSTEM_UUID/app/ding.js" >/dev/null 2>&1; then
    fail "system Zorin DING child is also running; two desktop-icon owners must not coexist"
fi
pass "system Zorin DING child is not running"

pass "known-good Wayland runtime verification complete"
