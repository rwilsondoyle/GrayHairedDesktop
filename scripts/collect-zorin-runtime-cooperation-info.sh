#!/usr/bin/env bash
# Read-only evidence collector for PR #45. It never evaluates code in GNOME Shell.
set -u

readonly UUID='zorin-desktop-icons@zorinos.com'
readonly EXTENSION_DIR="/usr/share/gnome-shell/extensions/$UUID"
readonly SOURCE_PATTERN='stateObj|lookupByUUID|extensionManager|_extensions|enable\(|disable\(|LaunchSubprocess|launchDesktop|WaylandClient|window_manager|query_window_belongs_to|owns_window|Desktop Icons |desktopManager|desktopGrid|Gio\.(DBus|SimpleActionGroup)|export|signal|connect'

printf '%s\n' 'GrayHaired Desktop: Zorin runtime-cooperation report (read only)'
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Extension UUID: %s\n' "$UUID"
printf 'Extension source: %s\n' "$EXTENSION_DIR"

printf '\n%s\n' '== Session and enabled-extension facts =='
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-unset}"
if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version 2>&1 || true
else
    printf '%s\n' 'gnome-shell command unavailable'
fi
if command -v gsettings >/dev/null 2>&1; then
    printf 'enabled-extensions: '
    gsettings get org.gnome.shell enabled-extensions 2>&1 || true
    printf 'disabled-extensions: '
    gsettings get org.gnome.shell disabled-extensions 2>&1 || true
else
    printf '%s\n' 'gsettings unavailable'
fi

printf '\n%s\n' '== Public Shell Extensions D-Bus state (if available) =='
if command -v gdbus >/dev/null 2>&1; then
    gdbus call --session \
        --dest org.gnome.Shell.Extensions \
        --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.GetExtensionInfo "$UUID" 2>&1 || true
else
    printf '%s\n' 'gdbus unavailable'
fi

printf '\n%s\n' '== Installed Zorin source cooperation matches =='
if [[ ! -d "$EXTENSION_DIR" ]]; then
    printf 'Extension directory is absent: %s\n' "$EXTENSION_DIR"
else
    mapfile -d '' files < <(find "$EXTENSION_DIR" -type f \
        \( -name '*.js' -o -name '*.mjs' -o -name 'metadata.json' \) -print0 \
        2>/dev/null | LC_ALL=C sort -z)
    if command -v rg >/dev/null 2>&1; then
        rg --no-heading -n -i -C 3 --max-count 80 -- "$SOURCE_PATTERN" \
            "${files[@]}" 2>/dev/null | sed -n '1,600p' || true
    elif ((${#files[@]})); then
        grep -Eni -C 3 -m 80 -- "$SOURCE_PATTERN" "${files[@]}" 2>/dev/null \
            | sed -n '1,600p' || true
    else
        printf '%s\n' 'No matching source files found.'
    fi
fi

printf '\n%s\n' '== Installed GNOME Shell extension-manager source matches =='
shell_sources=()
while IFS= read -r -d '' file; do shell_sources+=("$file"); done < <(
    find /usr/share/gnome-shell /usr/lib/gnome-shell /usr/lib64/gnome-shell \
        -type f \( -name 'extensionSystem.js' -o -name 'extension.js' \) -print0 \
        2>/dev/null | LC_ALL=C sort -z
)
if ((${#shell_sources[@]} == 0)); then
    printf '%s\n' 'No unpacked GNOME Shell extension-manager source found.'
elif command -v rg >/dev/null 2>&1; then
    rg --no-heading -n -C 4 -- 'lookupByUUID|lookup\(|stateObj|_extensions|_callExtension' \
        "${shell_sources[@]}" 2>/dev/null | sed -n '1,360p' || true
else
    grep -En -C 4 -- 'lookupByUUID|lookup\(|stateObj|_extensions|_callExtension' \
        "${shell_sources[@]}" 2>/dev/null | sed -n '1,360p' || true
fi

printf '\n%s\n' '== Process identities (observation only) =='
if command -v pgrep >/dev/null 2>&1; then
    pgrep -af 'com\.rastersoft\.ding|app/ding\.js|Desktop Icons' 2>&1 || true
else
    printf '%s\n' 'pgrep unavailable'
fi

printf '\n%s\n' 'No Shell Eval call was made. No setting, extension, process, window, actor,'
printf '%s\n' 'or installed file was changed.'
