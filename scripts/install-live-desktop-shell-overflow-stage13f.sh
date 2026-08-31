#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-overflow-control@grayhaired.tech"
EXT_ROOT="$HOME/.local/share/gnome-shell/extensions"
EXT="$EXT_ROOT/$UUID"
DRAWER="$HOME/.local/bin/grayhaired-desktop-items"
OLD_WATCHER="$HOME/.local/bin/grayhaired-overflow-watch"
OLD_AUTOSTART="$HOME/.config/autostart/grayhaired-overflow-watch.desktop"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[[ -n "$DESKTOP_DIR" ]] || DESKTOP_DIR="$HOME/Desktop"
OLD_TRIGGER="$DESKTOP_DIR/More Desktop Items.desktop"

fail() {
    printf '[GRAYHAIRED-OVERFLOW13F] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-OVERFLOW13F] PASS: %s\n' "$*"
}

[[ -x "$DRAWER" ]] || fail "Stage 13 drawer is not installed: $DRAWER"
mkdir -p "$EXT_ROOT"

# Retire the Stage 13C/13D desktop-file/watcher experiments so Stage 13F is the
# only overflow-control mechanism active. These files do not belong to DING's
# known-good core and are safe to remove.
pkill -f "$OLD_WATCHER" >/dev/null 2>&1 || true
rm -f "$OLD_AUTOSTART" "$OLD_TRIGGER"

# If a previous Stage 13F copy is loaded, disable only this helper extension
# before replacing its files. Never touch the main GrayHaired Live Desktop.
gnome-extensions disable "$UUID" >/dev/null 2>&1 || true
rm -rf "$EXT"
mkdir -p "$EXT"

cat > "$EXT/metadata.json" <<'JSON'
{
  "uuid": "grayhaired-overflow-control@grayhaired.tech",
  "name": "GrayHaired Overflow Control",
  "description": "Conditional More Desktop Items button for GrayHaired Live Desktop.",
  "shell-version": ["46"],
  "version": 1
}
JSON

cat > "$EXT/extension.js" <<'JS'
'use strict';

// GRAYHAIRED-SHELL-OVERFLOW-STAGE13F
const { Gio, GLib, St, Clutter } = imports.gi;
const Main = imports.ui.main;

const DESKTOP_SCHEMA = 'org.gnome.shell.extensions.zorin-desktop-icons';
const DRAWER = GLib.build_filenamev([GLib.get_home_dir(), '.local', 'bin', 'grayhaired-desktop-items']);
const TRIGGER_NAME = 'More Desktop Items.desktop';
const ICON_HEIGHT = {
    tiny: 80,
    small: 90,
    standard: 106,
    large: 138,
};
const CELL_EXTRA = 8;
const COLUMNS = 2;
const FALLBACK_SPECIAL_ICONS = 2; // Home + Trash on the tested Zorin setup.

let button = null;
let settings = null;
let settingsSignal = 0;
let monitorSignal = 0;
let timeoutId = 0;
let lastState = '';

function _desktopPath() {
    const path = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP);
    return path || GLib.build_filenamev([GLib.get_home_dir(), 'Desktop']);
}

function _countDesktopEntries() {
    const dir = Gio.File.new_for_path(_desktopPath());
    let count = 0;
    try {
        const enumerator = dir.enumerate_children(
            'standard::name',
            Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
            null
        );
        let info;
        while ((info = enumerator.next_file(null)) !== null) {
            const name = info.get_name();
            if (!name || name === TRIGGER_NAME || name.endsWith('.pre-grayhaired-stage13c'))
                continue;
            count++;
        }
        enumerator.close(null);
    } catch (e) {
        log(`[GRAYHAIRED-OVERFLOW13F] desktop count failed: ${e.message}`);
    }
    return count;
}

function _specialIconCount() {
    // Zorin has varied these key names across DING revisions. Inspect the
    // available schema keys and count known visible special icons when
    // possible; otherwise use the physically observed Home + Trash fallback.
    let count = 0;
    let matched = false;
    try {
        const keys = settings.list_keys();
        for (const candidate of [
            'show-home', 'show-home-icon', 'show-home-folder',
            'show-trash', 'show-trash-icon',
        ]) {
            if (!keys.includes(candidate))
                continue;
            matched = true;
            try {
                if (settings.get_boolean(candidate))
                    count++;
            } catch (e) {
                // Ignore a key with an unexpected type.
            }
        }
    } catch (e) {
        matched = false;
    }
    return matched ? count : FALLBACK_SPECIAL_ICONS;
}

function _iconSize() {
    try {
        const value = settings.get_string('icon-size');
        if (Object.prototype.hasOwnProperty.call(ICON_HEIGHT, value))
            return value;
    } catch (e) {
        log(`[GRAYHAIRED-OVERFLOW13F] icon-size read failed: ${e.message}`);
    }
    return 'standard';
}

function _primaryMonitor() {
    return Main.layoutManager.primaryMonitor || Main.layoutManager.monitors[0] || null;
}

function _capacity(size, monitor) {
    const cell = ICON_HEIGHT[size] + CELL_EXTRA;
    const rows = Math.max(1, Math.floor(monitor.height / cell));
    return { cell, rows, capacity: rows * COLUMNS };
}

function _positionButton(monitor) {
    if (!button || !monitor)
        return;

    // Keep clear of the bottom taskbar while visually anchoring the control to
    // the bottom of the left icon pane. This actor is Shell chrome, not a DING
    // child, so it consumes no desktop grid slot and cannot resize WebKit.
    const x = monitor.x + 12;
    const y = monitor.y + Math.max(12, monitor.height - 112);
    button.set_position(x, y);
}

function _launchDrawer() {
    try {
        Gio.Subprocess.new([DRAWER], Gio.SubprocessFlags.NONE);
    } catch (e) {
        log(`[GRAYHAIRED-OVERFLOW13F] drawer launch failed: ${e.message}`);
    }
}

function _evaluate() {
    if (!button || !settings)
        return GLib.SOURCE_CONTINUE;

    const monitor = _primaryMonitor();
    if (!monitor) {
        button.hide();
        return GLib.SOURCE_CONTINUE;
    }

    const size = _iconSize();
    const geometry = _capacity(size, monitor);
    const files = _countDesktopEntries();
    const special = _specialIconCount();
    const items = files + special;
    const overflow = items > geometry.capacity;

    _positionButton(monitor);
    overflow ? button.show() : button.hide();

    const state = `${size}:${files}:${special}:${geometry.rows}:${geometry.capacity}:${overflow}`;
    if (state !== lastState) {
        lastState = state;
        log(
            `[GRAYHAIRED-OVERFLOW13F] size=${size} files=${files} special=${special} ` +
            `items=${items} rows=${geometry.rows} columns=${COLUMNS} ` +
            `capacity=${geometry.capacity} overflow=${overflow}`
        );
    }

    return GLib.SOURCE_CONTINUE;
}

function init() {
}

function enable() {
    settings = new Gio.Settings({ schema_id: DESKTOP_SCHEMA });

    button = new St.Button({
        reactive: true,
        can_focus: true,
        track_hover: true,
        label: '▼  More Desktop Items',
        style: [
            'background-color: #ff7a00;',
            'color: white;',
            'font-weight: bold;',
            'border-radius: 12px;',
            'padding: 11px 16px;',
            'border: 2px solid rgba(255,255,255,0.85);',
            'box-shadow: 0 2px 8px rgba(0,0,0,0.45);',
        ].join(' '),
    });
    button.accessible_name = 'More Desktop Items';
    button.connect('clicked', _launchDrawer);

    Main.layoutManager.addChrome(button, {
        affectsInputRegion: true,
        trackFullscreen: false,
    });

    settingsSignal = settings.connect('changed::icon-size', _evaluate);
    monitorSignal = Main.layoutManager.connect('monitors-changed', _evaluate);
    timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, _evaluate);

    _evaluate();
    log('[GRAYHAIRED-OVERFLOW13F] enabled');
}

function disable() {
    if (timeoutId) {
        GLib.source_remove(timeoutId);
        timeoutId = 0;
    }
    if (settings && settingsSignal) {
        settings.disconnect(settingsSignal);
        settingsSignal = 0;
    }
    if (monitorSignal) {
        Main.layoutManager.disconnect(monitorSignal);
        monitorSignal = 0;
    }
    if (button) {
        Main.layoutManager.removeChrome(button);
        button.destroy();
        button = null;
    }
    settings = null;
    lastState = '';
    log('[GRAYHAIRED-OVERFLOW13F] disabled');
}
JS

chmod 0644 "$EXT/metadata.json" "$EXT/extension.js"

grep -Fq 'GRAYHAIRED-SHELL-OVERFLOW-STAGE13F' "$EXT/extension.js" || fail "Stage 13F marker missing"
grep -Fq 'Main.layoutManager.addChrome(button' "$EXT/extension.js" || fail "Shell chrome button missing"
grep -Fq "label: '▼  More Desktop Items'" "$EXT/extension.js" || fail "More button label missing"

pass "Stage 13F isolated GNOME Shell overflow helper installed"
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Main GrayHaired Live Desktop files were not modified."
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Log out and back into the same GNOME session so Shell discovers the new helper extension."
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "After login run: gnome-extensions enable $UUID"
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Then test Tiny, Small, Standard, and Large."
