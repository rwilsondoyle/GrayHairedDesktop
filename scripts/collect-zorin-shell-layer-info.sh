#!/usr/bin/env bash
# Read-only, targeted Shell-layer report for the installed Zorin Desktop Icons.
set -u

extension_dir='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
category_names=('Shell groups and stacking' 'Window lifecycle and platform' 'Workspace and geometry')
category_patterns=(
    'Main\.layoutManager|Main\.uiGroup|global\.(top_)?window_group|set_stack_position|lower|raise|stack|above|below|actor|windowActor|get_compositor_private|Clutter|St\.Widget|addChrome|trackChrome|_?backgroundGroup'
    'global\.display|window-created|\bmap\b|\bunmap\b|Meta\.Window(Type)?|get_window_type|desktop[ _]?window|Gtk\.Window|Gdk\.Window|Wayland|X11|WM_CLASS'
    'workspace|sticky|skip_taskbar|skip_pager|monitor|work[ _]?area|visibleArea|desktopManager|desktopGrid'
)
primary_files=(
    'extension.js'
    'gnomeShellOverride.js'
    'visibleArea.js'
    'emulateX11WindowType.js'
)
app_files=(
    'app/ding.js'
    'app/desktopManager.js'
    'app/desktopGrid.js'
)

printf '%s\n' 'GrayHaired Desktop: targeted Zorin Shell-layer report'
printf 'Extension path: %s\n' "$extension_dir"
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

if [[ ! -d "$extension_dir" ]]; then
    printf 'ERROR: expected extension directory does not exist: %s\n' "$extension_dir" >&2
    exit 1
fi

safe_file() {
    local relative_path="$1"
    local candidate="$extension_dir/$relative_path"
    local resolved
    if [[ ! -f "$candidate" || ! -r "$candidate" ]]; then
        printf 'UNAVAILABLE: %s\n' "$relative_path"
        return 1
    fi
    resolved="$(realpath -e -- "$candidate" 2>/dev/null)" || return 1
    case "$resolved" in
        "$extension_dir"/*) printf '%s\n' "$resolved" ;;
        *)
            printf 'REFUSED path outside fixed extension directory: %s\n' "$relative_path" >&2
            return 1
            ;;
    esac
}

print_matches() {
    local relative_path="$1"
    local resolved
    resolved="$(safe_file "$relative_path")" || return 0
    local index pattern
    printf '\n-- %s: targeted architecture matches --\n' "$relative_path"
    for index in "${!category_names[@]}"; do
        pattern="${category_patterns[$index]}"
        printf '\n[%s; 4 context lines; maximum 120 lines]\n' "${category_names[$index]}"
        if command -v rg >/dev/null 2>&1; then
            rg --line-number --ignore-case --context 4 --max-count 50 \
                -- "$pattern" "$resolved" 2>/dev/null \
                | sed -n '1,120p' || true
        else
            grep -Eni -C 4 -- "$pattern" "$resolved" 2>/dev/null \
                | sed -n '1,120p' || true
        fi
    done
}

printf '\n%s\n' '== Shell-side files: bounded opening sections =='
for relative_path in "${primary_files[@]}"; do
    resolved="$(safe_file "$relative_path")" || continue
    printf '\n-- %s: lines 1-180 --\n' "$relative_path"
    sed -n '1,180p' "$resolved"
done

printf '\n%s\n' '== Shell-side files: architecture matches =='
for relative_path in "${primary_files[@]}"; do
    print_matches "$relative_path"
done

printf '\n%s\n' '== Application-side files: architecture matches only =='
for relative_path in "${app_files[@]}"; do
    print_matches "$relative_path"
done

printf '\n%s\n' '== Interpretation questions =='
printf '%s\n' '1. Are visible icons drawn in GTK/client windows, Shell actors, or both?'
printf '%s\n' '2. Which Meta.Window/window actors are identified and how are they stacked?'
printf '%s\n' '3. What desktop role does emulateX11WindowType.js reproduce on Wayland?'
printf '%s\n' '4. Is there a lifecycle hook for a recognized surface directly below icon windows?'
printf '%s\n' 'This script does not modify, copy, patch, install, enable, disable, remove, or restart anything.'
