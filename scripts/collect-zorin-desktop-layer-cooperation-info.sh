#!/usr/bin/env bash
set -euo pipefail

readonly EXTENSION_DIR='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
readonly PATTERN='Main\.layoutManager|_backgroundGroup|uiGroup|global\.(top_)?window_group|add_child|addChrome|trackChrome|addTopChrome|background[^[:alnum:]_]*actor|desktop[^[:alnum:]_]*actor|Clutter\.|St\.(Widget|BoxLayout)|monitor[^[:alnum:]_]*group|Meta\.Window|window[^[:alnum:]_]*group|DBus|D-Bus|Gio\.DBus|export|register|coordina|interface|container|surface|set_child_(above|below|at)|raise|lower|stack'
readonly FILES=(
    extension.js
    emulateX11WindowType.js
    gnomeShellOverride.js
    visibleArea.js
    app/ding.js
    app/desktopManager.js
    app/desktopGrid.js
)

printf '%s\n' 'Zorin Desktop Icons cooperation/layer architecture (read only)'
printf 'Source: %s\n' "$EXTENSION_DIR"

if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf 'Error: fixed extension directory not found: %s\n' "$EXTENSION_DIR" >&2
    exit 1
fi

if command -v rg >/dev/null 2>&1; then
    readonly BACKEND='ripgrep'
elif command -v grep >/dev/null 2>&1; then
    readonly BACKEND='grep fallback'
else
    printf '%s\n' 'Error: neither ripgrep nor grep is available.' >&2
    exit 1
fi
printf 'Search backend: %s\n' "$BACKEND"

for relative in "${FILES[@]}"; do
    file="$EXTENSION_DIR/$relative"
    if [[ ! -f "$file" ]]; then
        printf '\n===== %s (not installed) =====\n' "$relative"
        continue
    fi
    resolved=$(realpath -e -- "$file") || {
        printf '\n===== %s (cannot resolve) =====\n' "$relative"
        continue
    }
    case "$resolved" in
        "$EXTENSION_DIR"/*) ;;
        *)
            printf 'Error: refused path outside fixed extension directory: %s\n' \
                "$relative" >&2
            exit 1
            ;;
    esac
    printf '\n===== %s (maximum 180 output lines) =====\n' "$relative"
    if [[ "$BACKEND" == 'ripgrep' ]]; then
        rg -n -i -C 5 --max-count 25 -- "$PATTERN" "$resolved" | head -n 180 || true
    else
        grep -n -i -E -C 5 -m 25 -- "$PATTERN" "$resolved" | head -n 180 || true
    fi
done

printf '\n%s\n' 'Interpretation checklist:'
printf '%s\n' \
    '1. Shell-owned icon actor/container, external Meta.Windows, or both?' \
    '2. Explicit layer/container coordination point?' \
    '3. Exported D-Bus or extension-cooperation interface?' \
    '4. Stable non-title registration below the icon surfaces?'
printf '%s\n' 'No files, processes, extensions, or settings were changed.'
