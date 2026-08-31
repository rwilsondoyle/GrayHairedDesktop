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
  "version": 2
}
JSON

cat > "$EXT/extension.js" <<'JS'
// GRAYHAIRED-SHELL-OVERFLOW-STAGE13F
// GNOME Shell 46 ES-module extension. This helper is intentionally isolated
// from the GrayHaired DING/WebKit child so a helper failure cannot break the
// live desktop surface.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const DESKTOP_SCHEMA = 'org.gnome.shell.extensions.zorin-desktop-icons';
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

export default class GrayHairedOverflowControl extends Extension {
    enable() {
        this._button = null;
        this._settings = null;
        this._settingsSignal = 0;
        this._monitorSignal = 0;
        this._timeoutId = 0;
        this._lastState = '';
        this._drawer = GLib.build_filenamev([
            GLib.get_home_dir(), '.local', 'bin', 'grayhaired-desktop-items',
        ]);

        try {
            this._settings = new Gio.Settings({schema_id: DESKTOP_SCHEMA});
        } catch (e) {
            console.error(`[GRAYHAIRED-OVERFLOW13F] settings init failed: ${e.message}`);
            return;
        }

        this._button = new St.Button({
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
        this._button.accessible_name = 'More Desktop Items';
        this._button.connect('clicked', () => this._launchDrawer());

        Main.layoutManager.addChrome(this._button, {
            affectsInputRegion: true,
            trackFullscreen: false,
        });

        this._settingsSignal = this._settings.connect(
            'changed::icon-size',
            () => this._evaluate()
        );
        this._monitorSignal = Main.layoutManager.connect(
            'monitors-changed',
            () => this._evaluate()
        );
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            2,
            () => this._evaluate()
        );

        this._evaluate();
        console.log('[GRAYHAIRED-OVERFLOW13F] enabled');
    }

    disable() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = 0;
        }
        if (this._settings && this._settingsSignal) {
            this._settings.disconnect(this._settingsSignal);
            this._settingsSignal = 0;
        }
        if (this._monitorSignal) {
            Main.layoutManager.disconnect(this._monitorSignal);
            this._monitorSignal = 0;
        }
        if (this._button) {
            Main.layoutManager.removeChrome(this._button);
            this._button.destroy();
            this._button = null;
        }
        this._settings = null;
        this._lastState = '';
        console.log('[GRAYHAIRED-OVERFLOW13F] disabled');
    }

    _desktopPath() {
        const path = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP);
        return path || GLib.build_filenamev([GLib.get_home_dir(), 'Desktop']);
    }

    _countDesktopEntries() {
        const dir = Gio.File.new_for_path(this._desktopPath());
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
            console.error(`[GRAYHAIRED-OVERFLOW13F] desktop count failed: ${e.message}`);
        }
        return count;
    }

    _specialIconCount() {
        let count = 0;
        let matched = false;
        try {
            const keys = this._settings.list_keys();
            for (const candidate of [
                'show-home', 'show-home-icon', 'show-home-folder',
                'show-trash', 'show-trash-icon',
            ]) {
                if (!keys.includes(candidate))
                    continue;
                matched = true;
                try {
                    if (this._settings.get_boolean(candidate))
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

    _iconSize() {
        try {
            const value = this._settings.get_string('icon-size');
            if (Object.prototype.hasOwnProperty.call(ICON_HEIGHT, value))
                return value;
        } catch (e) {
            console.error(`[GRAYHAIRED-OVERFLOW13F] icon-size read failed: ${e.message}`);
        }
        return 'standard';
    }

    _primaryMonitor() {
        return Main.layoutManager.primaryMonitor || Main.layoutManager.monitors[0] || null;
    }

    _capacity(size, monitor) {
        const cell = ICON_HEIGHT[size] + CELL_EXTRA;
        const rows = Math.max(1, Math.floor(monitor.height / cell));
        return {cell, rows, capacity: rows * COLUMNS};
    }

    _positionButton(monitor) {
        if (!this._button || !monitor)
            return;

        const x = monitor.x + 12;
        const y = monitor.y + Math.max(12, monitor.height - 112);
        this._button.set_position(x, y);
    }

    _launchDrawer() {
        try {
            Gio.Subprocess.new([this._drawer], Gio.SubprocessFlags.NONE);
        } catch (e) {
            console.error(`[GRAYHAIRED-OVERFLOW13F] drawer launch failed: ${e.message}`);
        }
    }

    _evaluate() {
        if (!this._button || !this._settings)
            return GLib.SOURCE_CONTINUE;

        const monitor = this._primaryMonitor();
        if (!monitor) {
            this._button.hide();
            return GLib.SOURCE_CONTINUE;
        }

        const size = this._iconSize();
        const geometry = this._capacity(size, monitor);
        const files = this._countDesktopEntries();
        const special = this._specialIconCount();
        const items = files + special;
        const overflow = items > geometry.capacity;

        this._positionButton(monitor);
        overflow ? this._button.show() : this._button.hide();

        const state = `${size}:${files}:${special}:${geometry.rows}:${geometry.capacity}:${overflow}`;
        if (state !== this._lastState) {
            this._lastState = state;
            console.log(
                `[GRAYHAIRED-OVERFLOW13F] size=${size} files=${files} special=${special} ` +
                `items=${items} rows=${geometry.rows} columns=${COLUMNS} ` +
                `capacity=${geometry.capacity} overflow=${overflow}`
            );
        }

        return GLib.SOURCE_CONTINUE;
    }
}
JS

chmod 0644 "$EXT/metadata.json" "$EXT/extension.js"

grep -Fq 'GRAYHAIRED-SHELL-OVERFLOW-STAGE13F' "$EXT/extension.js" || fail "Stage 13F marker missing"
grep -Fq "import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';" "$EXT/extension.js" || fail "GNOME 46 Extension import missing"
grep -Fq 'export default class GrayHairedOverflowControl extends Extension' "$EXT/extension.js" || fail "GNOME 46 extension class missing"
grep -Fq 'Main.layoutManager.addChrome(this._button' "$EXT/extension.js" || fail "Shell chrome button missing"
grep -Fq "label: '▼  More Desktop Items'" "$EXT/extension.js" || fail "More button label missing"

pass "Stage 13F GNOME 46 overflow helper installed"
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Main GrayHaired Live Desktop files were not modified."
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Because the helper extension files changed, log out and back into the same GNOME session once."
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "After login run: gnome-extensions enable $UUID"
printf '[GRAYHAIRED-OVERFLOW13F] INFO: %s\n' "Then test Tiny, Small, Standard, and Large."
