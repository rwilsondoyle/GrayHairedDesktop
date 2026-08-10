#!/usr/bin/env bash
set -euo pipefail

readonly EXTENSION_DIR='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
readonly PATTERN='WaylandClient|wayland_client|waylandClient|new .*Wayland|Meta\.Wayland|Shell\.Wayland|launchDesktop|spawnv|spawn|Gio\.Subprocess|SubprocessLauncher|query_window_belongs_to|hide_from_window_list|show_in_window_list|connect_after.*map|window_manager.*map|child_watch|wait_async|force_exit|terminate|restart|emulateX11WindowType'
readonly EXTENSION_JS="$EXTENSION_DIR/extension.js"

printf '%s\n' 'Zorin Desktop Icons Wayland-client architecture (read only)'
printf 'Source: %s\n' "$EXTENSION_DIR"

if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf 'Not found: %s\n' "$EXTENSION_DIR" >&2
    exit 1
fi

for required_command in sort head sed nl cut; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'Error: required standard tool is unavailable: %s\n' \
            "$required_command" >&2
        exit 1
    fi
done

if command -v rg >/dev/null 2>&1; then
    readonly SEARCH_BACKEND='ripgrep'
elif command -v grep >/dev/null 2>&1; then
    readonly SEARCH_BACKEND='grep fallback'
else
    printf '%s\n' \
        'Error: neither ripgrep nor the grep fallback is available.' >&2
    exit 1
fi

printf 'Search backend: %s\n\n' "$SEARCH_BACKEND"

status=0
if [[ "$SEARCH_BACKEND" == 'ripgrep' ]]; then
    matches=$(rg -l --glob '*.js' "$PATTERN" "$EXTENSION_DIR" | sort) || status=$?
else
    matches=$(grep -r -l -E --include='*.js' "$PATTERN" "$EXTENSION_DIR" \
        | sort) || status=$?
fi

# Both search tools use status 1 for a valid search with no matches. Any other
# nonzero result is a diagnostic failure and must not be reported as zero files.
if ((status > 1)); then
    printf 'Error: %s search failed with status %d.\n' "$SEARCH_BACKEND" "$status" >&2
    exit "$status"
fi

mapfile -t all_files <<<"$matches"
if [[ -z "$matches" ]]; then
    all_files=()
fi
files=("${all_files[@]:0:12}")

printf 'Matching JavaScript files (%d; at most 12 shown):\n' "${#files[@]}"
printf '  %s\n' "${files[@]#"$EXTENSION_DIR"/}"

for file in "${files[@]}"; do
    printf '\n===== %s =====\n' "${file#"$EXTENSION_DIR"/}"
    # Per-file bounds prevent generated/application code from consuming the
    # report before the Shell integration call sites are reached.
    if [[ "$SEARCH_BACKEND" == 'ripgrep' ]]; then
        rg -n -C 4 --max-count 18 "$PATTERN" "$file" | head -n 220 || true
    else
        grep -n -E -C 4 -m 18 "$PATTERN" "$file" | head -n 220 || true
    fi
done

if [[ -f "$EXTENSION_JS" ]]; then
    printf '\n===== extension.js opening/imports (lines 1-140) =====\n'
    sed -n '1,140p' "$EXTENSION_JS" | nl -ba -v 1

    if [[ "$SEARCH_BACKEND" == 'ripgrep' ]]; then
        launch_line=$(rg -n -m 1 \
            '^[[:space:]]*(async[[:space:]]+)?launchDesktop[[:space:]]*\(' \
            "$EXTENSION_JS" | cut -d: -f1) || true
    else
        launch_line=$(grep -n -m 1 -E \
            '^[[:space:]]*(async[[:space:]]+)?launchDesktop[[:space:]]*\(' \
            "$EXTENSION_JS" | cut -d: -f1) || true
    fi
    if [[ -n "$launch_line" ]]; then
        start=$((launch_line > 20 ? launch_line - 20 : 1))
        end=$((launch_line + 140))
        printf '\n===== extension.js launchDesktop body (lines %d-%d) =====\n' \
            "$start" "$end"
    else
        start=260
        end=360
        printf '\n===== extension.js launchDesktop fallback range (lines %d-%d) =====\n' \
            "$start" "$end"
        printf '%s\n' 'Method definition was not located dynamically; showing the known installed range.'
    fi
    sed -n "${start},${end}p" "$EXTENSION_JS" | nl -ba -v "$start"
else
    printf '\nMissing expected file: %s\n' "$EXTENSION_JS" >&2
    exit 1
fi

printf '\nNo files were modified, copied, installed, enabled, or restarted.\n'
