#!/usr/bin/env bash
# Read-only architecture report for Zorin Desktop Icons on the target system.
set -u

extension_dir='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
metadata="$extension_dir/metadata.json"
match_pattern='background|desktop|window|actor|monitor|work[ _-]?area|layoutManager|chrome|Meta\.Window|global\.window_group|window_group|addChrome|set_child_(above|below)_sibling|lower|raise|stack|desktop[ _-]?icons|desktopManager|desktopGrid'

printf '%s\n' 'GrayHaired Desktop: Zorin Desktop Icons read-only report'
printf 'Extension path: %s\n' "$extension_dir"
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

if [[ ! -d "$extension_dir" ]]; then
    printf 'ERROR: expected extension directory does not exist: %s\n' "$extension_dir" >&2
    exit 1
fi

printf '\n%s\n' '== metadata.json (maximum 240 lines) =='
if [[ -r "$metadata" ]]; then
    sed -n '1,240p' "$metadata"
else
    printf '%s\n' 'metadata.json is missing or unreadable'
fi

printf '\n%s\n' '== Installed tree (maximum 240 entries; depth 4) =='
find "$extension_dir" -maxdepth 4 -mindepth 1 -printf '%P\n' 2>/dev/null \
    | LC_ALL=C sort \
    | sed -n '1,240p'

printf '\n%s\n' '== JavaScript files (maximum 160 entries) =='
find "$extension_dir" -type f \( -name '*.js' -o -name '*.mjs' \) -printf '%P\n' 2>/dev/null \
    | LC_ALL=C sort \
    | sed -n '1,160p'

printf '\n%s\n' '== Architecture-related JavaScript matches =='
printf '%s\n' '(case-insensitive, two context lines, maximum 320 output lines)'
mapfile -d '' js_files < <(
    find "$extension_dir" -type f \( -name '*.js' -o -name '*.mjs' \) -print0 2>/dev/null \
        | LC_ALL=C sort -z
)
if ((${#js_files[@]} == 0)); then
    printf '%s\n' 'No JavaScript files found.'
elif command -v rg >/dev/null 2>&1; then
    # sed provides a global output bound without terminating rg early.
    rg --no-heading --line-number --ignore-case --context 2 \
        --glob '*.js' --glob '*.mjs' \
        -- "$match_pattern" "$extension_dir" 2>/dev/null \
        | sed -n '1,320p' || true
else
    printf '%s\n' 'ripgrep is unavailable; using grep with the same global output bound.'
    grep -Eni -C 2 -- "$match_pattern" "${js_files[@]}" 2>/dev/null \
        | sed -n '1,320p' || true
fi

printf '\n%s\n' '== Interpretation reminder =='
printf '%s\n' 'Look for Clutter/St actors added to Shell groups (Shell-owned actors),'
printf '%s\n' 'Meta.Window/window-created handling (client windows), or evidence of both.'
printf '%s\n' 'This report does not modify, enable, disable, install, remove, or restart anything.'
