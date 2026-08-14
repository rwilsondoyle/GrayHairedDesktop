#!/usr/bin/env bash
set -euo pipefail

readonly PREFIX='[GrayHaired Desktop Layer][LayerHierarchy]'

printf '%s\n' 'GrayHaired Desktop: GNOME Shell layer hierarchy (read only)'
printf 'GNOME Shell: '
if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version 2>&1
else
    printf '%s\n' 'not available on PATH'
fi

if ! command -v journalctl >/dev/null 2>&1; then
    printf '%s\n' 'Error: journalctl is unavailable.' >&2
    exit 1
fi

lines="$({
    journalctl --user -b --no-pager -o cat -n 4000 2>/dev/null || true
    journalctl -b --no-pager -o cat -n 4000 _COMM=gnome-shell 2>/dev/null || true
} | awk -v prefix="$PREFIX" 'index($0, prefix) { print }' | tail -n 80)"

if [[ -n "$lines" ]]; then
    printf '%s\n' "$lines" | awk '!seen[$0]++'
else
    printf '%s\n' '(no hierarchy lines found; enable only the reviewed development prototype first)'
fi

printf '%s\n' \
    'This collector reads journal entries only; it does not run GJS, create actors, install, enable, or modify anything.'
