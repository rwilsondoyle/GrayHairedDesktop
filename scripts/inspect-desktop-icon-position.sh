#!/usr/bin/env bash
# Read-only desktop icon-position report for the physical Zorin test system.
set -u

readonly EXTENSION_DIR='/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com'
readonly POSITION_PATTERN='position|coordinate|grid|drop|metadata::|set_attribute|setAttribute|set_metadata|setMetadata'

printf '%s\n' 'My Desktop: read-only desktop icon-position report'
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Session type: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Desktop session: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'Wayland display: %s\n' "${WAYLAND_DISPLAY:-not set}"
printf 'X11 display: %s\n' "${DISPLAY:-not set}"

desktop_dir="$HOME/Desktop"
if command -v xdg-user-dir >/dev/null 2>&1; then
    resolved_desktop="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    if [[ -n "$resolved_desktop" ]]; then
        desktop_dir="$resolved_desktop"
    fi
fi

printf '\n%s\n' '== Desktop directory =='
printf 'Resolved path: %s\n' "$desktop_dir"
if [[ -d "$desktop_dir" ]]; then
    find "$desktop_dir" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null \
        | LC_ALL=C sort
else
    printf '%s\n' 'Directory is absent or unreadable.'
fi

printf '\n%s\n' '== GIO information for desktop objects =='
printf '%s\n' '(Read this section before and after manually dragging one icon.)'
if ! command -v gio >/dev/null 2>&1; then
    printf '%s\n' 'gio is unavailable.'
elif [[ ! -d "$desktop_dir" ]]; then
    printf '%s\n' 'Desktop directory is unavailable.'
else
    while IFS= read -r -d '' item; do
        printf '\n--- %s ---\n' "$(basename "$item")"
        gio info -a '*' -- "$item" 2>&1 || true
    done < <(find "$desktop_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | LC_ALL=C sort -z)
fi

printf '\n%s\n' '== Extended attributes (when an existing reader is installed) =='
if command -v getfattr >/dev/null 2>&1; then
    getfattr --absolute-names -d -m - -- "$desktop_dir" "$desktop_dir"/* 2>&1 || true
elif command -v xattr >/dev/null 2>&1; then
    xattr -l -- "$desktop_dir" "$desktop_dir"/* 2>&1 || true
else
    printf '%s\n' 'Neither getfattr nor xattr is installed; nothing was installed by this script.'
fi

printf '\n%s\n' '== Relevant GNOME settings (read-only) =='
if command -v gsettings >/dev/null 2>&1; then
    while IFS= read -r schema; do
        case "$schema" in
            *desktop*|*ding*|*nautilus*|*zorin*)
                printf '\n--- %s ---\n' "$schema"
                gsettings list-recursively "$schema" 2>&1 || true
                ;;
        esac
    done < <(gsettings list-schemas 2>/dev/null | LC_ALL=C sort)
else
    printf '%s\n' 'gsettings is unavailable.'
fi

printf '\n%s\n' '== Display geometry (read-only, when available) =='
if command -v xrandr >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xrandr --current 2>&1 || true
else
    printf '%s\n' 'xrandr geometry is unavailable in this session.'
fi

printf '\n%s\n' '== Installed Zorin provider position-related source =='
printf 'Provider path: %s\n' "$EXTENSION_DIR"
if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf '%s\n' 'Installed provider source is absent or unreadable.'
elif command -v rg >/dev/null 2>&1; then
    rg --no-heading --line-number --ignore-case --context 2 \
        --glob '*.js' --glob '*.mjs' -- "$POSITION_PATTERN" "$EXTENSION_DIR" 2>&1 \
        | sed -n '1,600p' || true
else
    mapfile -d '' source_files < <(
        find "$EXTENSION_DIR" -type f \( -name '*.js' -o -name '*.mjs' \) -print0 2>/dev/null
    )
    if ((${#source_files[@]})); then
        grep -Eni -C 2 -- "$POSITION_PATTERN" "${source_files[@]}" 2>/dev/null \
            | sed -n '1,600p' || true
    else
        printf '%s\n' 'No JavaScript provider source was found.'
    fi
fi

printf '\n%s\n' '== Safety statement =='
printf '%s\n' 'This report only reads files, attributes, settings, source, and display state.'
printf '%s\n' 'It does not move icons, set metadata, restart Shell, or alter the extension.'
