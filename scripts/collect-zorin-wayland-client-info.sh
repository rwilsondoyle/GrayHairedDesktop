#!/usr/bin/env bash
set -euo pipefail

readonly EXTENSION_DIR='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
readonly PATTERN='WaylandClient|query_window_belongs_to|waylandClient|wayland_client|connect_after.*map|window_manager.*map|spawn|launch|Subprocess|child_watch|wait_async|force_exit|terminate|restart|emulateX11WindowType'

printf '%s\n' 'Zorin Desktop Icons Wayland-client architecture (read only)'
printf 'Source: %s\n\n' "$EXTENSION_DIR"

if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf 'Not found: %s\n' "$EXTENSION_DIR" >&2
    exit 1
fi

mapfile -t files < <(
    rg -l --glob '*.js' "$PATTERN" "$EXTENSION_DIR" \
        | sort \
        | head -n 12
)

printf 'Matching JavaScript files (%d; at most 12 shown):\n' "${#files[@]}"
printf '  %s\n' "${files[@]#"$EXTENSION_DIR"/}"

for file in "${files[@]}"; do
    printf '\n===== %s =====\n' "${file#"$EXTENSION_DIR"/}"
    # Per-file bounds prevent generated/application code from consuming the
    # report before the Shell integration call sites are reached.
    rg -n -C 4 --max-count 18 "$PATTERN" "$file" | head -n 220 || true
done

printf '\nNo files were modified, copied, installed, enabled, or restarted.\n'
