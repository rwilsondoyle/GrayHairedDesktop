#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
APP="$EXT/app"
DING="$APP/ding.js"
WAIT_SECONDS=20

log() {
    printf '[GRAYHAIRED-RELOAD] %s\n' "$*"
}

fail() {
    printf '[GRAYHAIRED-RELOAD] ERROR: %s\n' "$*" >&2
    exit 1
}

get_pids() {
    pgrep -f "gjs $DING -E -P $APP" 2>/dev/null || true
}

extension_state() {
    gnome-extensions info "$UUID" 2>/dev/null | awk -F': ' '/State:/ {print $2; exit}'
}

if [[ ! -f "$DING" ]]; then
    fail "GrayHaired DING is not installed at $DING"
fi

state="$(extension_state)"
if [[ "$state" != "ACTIVE" ]]; then
    cat >&2 <<EOF
[GRAYHAIRED-RELOAD] ERROR: $UUID is not ACTIVE (state: ${state:-unknown}).

This development reload intentionally does NOT enable/disable GNOME extensions.
Restore or log into the normal session first, then run this script again.
EOF
    exit 2
fi

mapfile -t old_pids < <(get_pids)
if (( ${#old_pids[@]} == 0 )); then
    fail "The extension is ACTIVE but no GrayHaired DING child process was found. Refusing to toggle GNOME extensions automatically."
fi

log "Restarting only the GrayHaired DING/WebKit child process."
log "GNOME Shell, Zorin Taskbar, Zorin AppIndicators, and other extensions will not be toggled."
log "Old PID(s): ${old_pids[*]}"

kill -TERM "${old_pids[@]}"

# Wait for every process we explicitly stopped to disappear.
for ((i = 0; i < WAIT_SECONDS * 10; i++)); do
    all_gone=true
    for pid in "${old_pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            all_gone=false
            break
        fi
    done
    $all_gone && break
    sleep 0.1
done

for pid in "${old_pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        fail "Old GrayHaired process $pid did not exit after SIGTERM."
    fi
done

# The DING GNOME extension owns the child and is designed to relaunch it when
# the desktop program exits unexpectedly while the extension remains enabled.
new_pid=""
for ((i = 0; i < WAIT_SECONDS * 4; i++)); do
    mapfile -t current_pids < <(get_pids)
    if (( ${#current_pids[@]} == 1 )); then
        candidate="${current_pids[0]}"
        old=false
        for pid in "${old_pids[@]}"; do
            [[ "$candidate" == "$pid" ]] && old=true
        done
        if ! $old; then
            new_pid="$candidate"
            break
        fi
    elif (( ${#current_pids[@]} > 1 )); then
        log "Multiple GrayHaired child processes detected during restart: ${current_pids[*]}"
        log "Stopping the duplicates and allowing the extension owner to relaunch one clean child."
        kill -TERM "${current_pids[@]}" 2>/dev/null || true
    fi
    sleep 0.25
done

if [[ -z "$new_pid" ]]; then
    mapfile -t final_pids < <(get_pids)
    printf '[GRAYHAIRED-RELOAD] Final child PID(s): %s\n' "${final_pids[*]:-none}" >&2
    fail "A single replacement DING/WebKit process did not appear within ${WAIT_SECONDS}s. No GNOME extensions were toggled."
fi

# Give GTK/WebKit a moment to create the desktop window, then verify that the
# replacement process is still alive and unique.
sleep 1
mapfile -t final_pids < <(get_pids)
if (( ${#final_pids[@]} != 1 )) || [[ "${final_pids[0]:-}" != "$new_pid" ]]; then
    fail "Restart did not settle to exactly one GrayHaired process. Found: ${final_pids[*]:-none}"
fi

log "Reload complete. New PID: $new_pid"
log "Extension state remains: $(extension_state)"
