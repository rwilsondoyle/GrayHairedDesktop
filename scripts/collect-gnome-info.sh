#!/usr/bin/env bash
# Read-only GNOME/Zorin facts for Desktop Mode feasibility reports.
set -u

printf '%s\n' 'GrayHaired Desktop GNOME environment report'
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'OS: '
if [[ -r /etc/os-release ]]; then
    (. /etc/os-release; printf '%s\n' "${PRETTY_NAME:-unknown}")
else
    printf '%s\n' 'unknown'
fi
printf 'Session type: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Current desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'GNOME Shell: '
if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version 2>&1
else
    printf '%s\n' 'not installed or not on PATH'
fi

if ! command -v gnome-extensions >/dev/null 2>&1; then
    printf '%s\n' 'gnome-extensions: not installed or not on PATH'
    exit 0
fi

printf '%s\n' 'Enabled extensions:'
enabled="$(gnome-extensions list --enabled 2>/dev/null || true)"
if [[ -z "$enabled" ]]; then
    printf '%s\n' '  (none reported)'
else
    while IFS= read -r uuid; do
        [[ -n "$uuid" ]] || continue
        printf '  %s\n' "$uuid"
        gnome-extensions info "$uuid" 2>/dev/null \
            | sed -n -E 's/^[[:space:]]*(Name|Description|Path|Version|State):/    \1:/p'
    done <<< "$enabled"
fi

printf '%s\n' 'Desktop-icon provider candidates:'
candidates="$(
    while IFS= read -r uuid; do
        [[ -n "$uuid" ]] || continue
        info="$(gnome-extensions info "$uuid" 2>/dev/null || true)"
        if printf '%s\n%s\n' "$uuid" "$info" \
            | tr '[:upper:]' '[:lower:]' \
            | grep -Eq 'desktop[ -]?icons|ding'; then
            printf '%s\n' "$uuid"
        fi
    done <<< "$enabled"
)"
if [[ -n "$candidates" ]]; then
    printf '%s\n' "$candidates" | sed 's/^/  /'
else
    printf '%s\n' '  none detected; inspect disabled/system extensions manually'
fi
