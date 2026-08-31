#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$SYSTEM_UUID"
TEST_EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"

log() {
    printf '[GRAYHAIRED-RECOVERY] %s\n' "$*"
}

pass() {
    log "PASS: $*"
}

fail() {
    log "FAIL: $*" >&2
    exit 1
}

extension_enabled() {
    gnome-extensions info "$1" 2>/dev/null | awk -F': ' '/Enabled:/ {print $2; exit}'
}

extension_state() {
    gnome-extensions info "$1" 2>/dev/null | awk -F': ' '/State:/ {print $2; exit}'
}

[[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] || fail "current session is not Wayland"
pass "current session is Wayland"

[[ -d "$SYSTEM_EXT" ]] || fail "system Zorin Desktop Icons extension is missing: $SYSTEM_EXT"
[[ -f "$SYSTEM_EXT/metadata.json" ]] || fail "system Zorin metadata.json is missing"
[[ -f "$SYSTEM_EXT/app/ding.js" ]] || fail "system Zorin DING child is missing"
pass "system Zorin Desktop Icons installation is present"

if grep -Rqs 'GrayHairedDesktop\|GRAYHAIRED-' "$SYSTEM_EXT"; then
    fail "GrayHaired marker found inside the system Zorin extension tree; refusing recovery assumptions"
fi
pass "system Zorin extension tree contains no GrayHaired markers"

[[ -d "$TEST_EXT" ]] || fail "GrayHaired user-local extension tree is not installed: $TEST_EXT"
[[ -f "$TEST_EXT/metadata.json" ]] || fail "GrayHaired metadata.json is missing"
[[ -f "$TEST_EXT/app/ding.js" ]] || fail "GrayHaired DING child is missing"
pass "GrayHaired user-local extension installation is present"

system_enabled="$(extension_enabled "$SYSTEM_UUID")"
test_enabled="$(extension_enabled "$TEST_UUID")"
test_state="$(extension_state "$TEST_UUID")"

log "INFO: $SYSTEM_UUID enabled=${system_enabled:-unknown}"
log "INFO: $TEST_UUID enabled=${test_enabled:-unknown} state=${test_state:-unknown}"

mapfile -t gray_pids < <(pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' 2>/dev/null || true)
mapfile -t zorin_pids < <(pgrep -f '/zorin-desktop-icons@zorinos.com/app/ding.js' 2>/dev/null || true)

if (( ${#gray_pids[@]} == 1 )); then
    pass "exactly one GrayHaired DING/WebKit child is running (PID ${gray_pids[0]})"
elif (( ${#gray_pids[@]} == 0 )); then
    log "INFO: no GrayHaired DING child is currently running"
else
    fail "multiple GrayHaired DING children are running: ${gray_pids[*]}"
fi

if (( ${#zorin_pids[@]} == 0 )); then
    pass "system Zorin DING child is not currently running"
else
    log "INFO: system Zorin DING child already running: ${zorin_pids[*]}"
fi

pass "recovery prerequisites are present"
log "No changes were made."
log "Actual removal requires the explicit command:"
log "  bash ~/GrayHairedDesktop/scripts/remove-wayland-separate-ding-prototype.sh --apply"
