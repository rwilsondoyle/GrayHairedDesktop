#!/usr/bin/env bash
# Read-only collector for API diagnostics emitted inside the GNOME Shell process.
set -u

prefix='[GrayHaired Desktop Layer][API]'
printf '%s\n' 'GrayHaired Desktop: GNOME Shell runtime API log collector'
printf 'GNOME Shell: '
if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version 2>&1
else
    printf '%s\n' 'not installed or not on PATH'
fi

if ! command -v journalctl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: journalctl is not installed or not on PATH' >&2
    exit 1
fi

printf '%s\n' 'Runtime API lines from the current boot (maximum 120):'
lines="$({
    journalctl --user -b --no-pager -o cat -n 3000 2>/dev/null || true
    journalctl -b --no-pager -o cat -n 3000 _COMM=gnome-shell 2>/dev/null || true
} | awk -v prefix="$prefix" 'index($0, prefix) { print }' | tail -n 120)"

if [[ -n "$lines" ]]; then
    printf '%s\n' "$lines" | awk '!seen[$0]++'
else
    printf '%s\n' '(none found; the uninstalled prototype has not emitted Shell-context diagnostics)'
fi

printf '%s\n' 'This script only reads journal entries; it does not run GJS, install, or enable anything.'
