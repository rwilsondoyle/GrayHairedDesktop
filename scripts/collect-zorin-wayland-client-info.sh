#!/usr/bin/env bash
set -euo pipefail

readonly EXTENSION_DIR='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
readonly PATTERN='WaylandClient|query_window_belongs_to|waylandClient|wayland_client|connect_after.*map|window_manager.*map|spawn|launch|Subprocess|child_watch|wait_async|force_exit|terminate|restart|emulateX11WindowType'

printf '%s\n' 'Zorin Desktop Icons Wayland-client architecture (read only)'
printf 'Source: %s\n' "$EXTENSION_DIR"

if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf 'Not found: %s\n' "$EXTENSION_DIR" >&2
    exit 1
fi

if command -v rg >/dev/null 2>&1; then
    readonly SEARCH_BACKEND='ripgrep'
elif command -v grep >/dev/null 2>&1 \
    && command -v sort >/dev/null 2>&1 \
    && command -v head >/dev/null 2>&1; then
    readonly SEARCH_BACKEND='grep fallback'
else
    printf '%s\n' \
        'Error: neither ripgrep nor the grep/sort/head fallback is available.' >&2
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

printf '\nNo files were modified, copied, installed, enabled, or restarted.\n'
