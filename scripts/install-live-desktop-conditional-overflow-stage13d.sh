#!/usr/bin/env bash
set -euo pipefail

BIN="$HOME/.local/bin/grayhaired-desktop-items"
WATCHER="$HOME/.local/bin/grayhaired-overflow-watch"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART="$AUTOSTART_DIR/grayhaired-overflow-watch.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
ICON="$ICON_DIR/grayhaired-more-desktop-items.svg"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[[ -n "$DESKTOP_DIR" ]] || DESKTOP_DIR="$HOME/Desktop"
TRIGGER="$DESKTOP_DIR/More Desktop Items.desktop"

fail() {
    printf '[GRAYHAIRED-DRAWER13D] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-DRAWER13D] PASS: %s\n' "$*"
}

[[ -x "$BIN" ]] || fail "Stage 13 drawer is not installed: $BIN"
mkdir -p "$(dirname "$WATCHER")" "$AUTOSTART_DIR" "$ICON_DIR" "$DESKTOP_DIR"

# Remove the always-visible Stage 13C trigger. Stage 13D recreates it only when
# the current desktop really overflows.
rm -f "$TRIGGER"

cat > "$ICON" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <circle cx="64" cy="64" r="58" fill="#ff7a00"/>
  <circle cx="64" cy="64" r="50" fill="#ff9a1f"/>
  <path d="M35 43h58v12H35zM35 62h58v12H35z" fill="#fff"/>
  <path d="M46 82h36L64 103z" fill="#fff"/>
</svg>
SVG
chmod 0644 "$ICON"

cat > "$WATCHER" <<'PY'
#!/usr/bin/env python3
# GRAYHAIRED-CONDITIONAL-OVERFLOW-STAGE13D

import gi
gi.require_version('Gio', '2.0')
gi.require_version('GLib', '2.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gio, GLib, Gdk
from pathlib import Path
import os

SCHEMA = 'org.gnome.shell.extensions.zorin-desktop-icons'
TRIGGER_NAME = 'More Desktop Items.desktop'
BIN = str(Path.home() / '.local/bin/grayhaired-desktop-items')
ICON = 'grayhaired-more-desktop-items'
ICON_HEIGHT = {'tiny': 80, 'small': 90, 'standard': 106, 'large': 138}
ELEMENT_EXTRA = 8
COLUMNS = 2
CHECK_MS = 1500


def desktop_path():
    p = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP)
    return Path(p) if p else Path.home() / 'Desktop'


def get_workarea_height():
    try:
        display = Gdk.Display.get_default()
        if display is not None:
            monitor = display.get_primary_monitor()
            if monitor is None and display.get_n_monitors() > 0:
                monitor = display.get_monitor(0)
            if monitor is not None:
                return int(monitor.get_workarea().height)
    except Exception:
        pass
    # Conservative fallback for the target 1366x768-class machine. The work
    # area normally excludes the taskbar, so 700 is safer than using 768.
    return 700


def count_real_items(desktop):
    try:
        return sum(1 for p in desktop.iterdir()
                   if p.name not in ('.', '..', TRIGGER_NAME)
                   and not p.name.endswith('.pre-grayhaired-stage13c'))
    except Exception:
        return 0


def current_icon_size(settings):
    try:
        value = settings.get_string('icon-size')
        if value in ICON_HEIGHT:
            return value
    except Exception:
        pass
    return 'standard'


def capacity_for(size):
    work_h = max(1, get_workarea_height())
    cell_h = ICON_HEIGHT[size] + ELEMENT_EXTRA
    rows = max(1, work_h // cell_h)
    return rows * COLUMNS, rows, work_h, cell_h


def write_trigger(path):
    text = f'''[Desktop Entry]\nType=Application\nVersion=1.0\nName=More Desktop Items\nComment=Show desktop items that do not fit on screen\nExec={BIN}\nIcon={ICON}\nTerminal=false\nStartupNotify=true\nCategories=Utility;\nX-GrayHaired-Stage=13D\n'''
    old = None
    try:
        old = path.read_text(encoding='utf-8')
    except Exception:
        pass
    if old != text:
        path.write_text(text, encoding='utf-8')
        os.chmod(path, 0o755)
        try:
            f = Gio.File.new_for_path(str(path))
            f.set_attribute_string('metadata::trusted', 'true', Gio.FileQueryInfoFlags.NONE, None)
            # Best-effort hint for DING/Nautilus-compatible position metadata.
            # If unsupported it is harmless; users can still drag the icon.
            f.set_attribute_string('metadata::nautilus-icon-position', '20,620', Gio.FileQueryInfoFlags.NONE, None)
        except Exception:
            pass
        print(f'[GRAYHAIRED-DRAWER13D] shown: {path}', flush=True)


def remove_trigger(path):
    if path.exists():
        try:
            path.unlink()
            print(f'[GRAYHAIRED-DRAWER13D] hidden: {path}', flush=True)
        except Exception as exc:
            print(f'[GRAYHAIRED-DRAWER13D] remove failed: {exc}', flush=True)


def evaluate(settings):
    desktop = desktop_path()
    desktop.mkdir(parents=True, exist_ok=True)
    trigger = desktop / TRIGGER_NAME
    size = current_icon_size(settings)
    count = count_real_items(desktop)
    capacity, rows, work_h, cell_h = capacity_for(size)

    # Only show More when real items exceed the number of actual DING slots.
    # If every real item fits, the trigger disappears completely.
    overflow = count > capacity
    print(
        f'[GRAYHAIRED-DRAWER13D] size={size} items={count} '
        f'workarea={work_h}px cell={cell_h}px rows={rows} '
        f'columns={COLUMNS} capacity={capacity} overflow={str(overflow).lower()}',
        flush=True,
    )
    if overflow:
        write_trigger(trigger)
    else:
        remove_trigger(trigger)
    return True


def main():
    settings = Gio.Settings.new(SCHEMA)
    evaluate(settings)
    settings.connect('changed::icon-size', lambda *_: evaluate(settings))

    desktop = Gio.File.new_for_path(str(desktop_path()))
    try:
        monitor = desktop.monitor_directory(Gio.FileMonitorFlags.NONE, None)
        monitor.connect('changed', lambda *_: GLib.timeout_add(250, evaluate, settings))
    except Exception:
        monitor = None

    GLib.timeout_add(CHECK_MS, evaluate, settings)
    loop = GLib.MainLoop()
    loop.run()


if __name__ == '__main__':
    main()
PY
chmod 0755 "$WATCHER"

cat > "$AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=GrayHaired Desktop Overflow Watch
Comment=Show More Desktop Items only when the icon pane overflows
Exec=$WATCHER
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
chmod 0644 "$AUTOSTART"

# Stop any older watcher, then start the newly installed one for this session.
pkill -f "$WATCHER" >/dev/null 2>&1 || true
nohup "$WATCHER" >"$HOME/.cache/grayhaired-overflow-watch.log" 2>&1 &
sleep 2

[[ -x "$WATCHER" ]] || fail "overflow watcher was not installed"
[[ -f "$AUTOSTART" ]] || fail "autostart entry was not installed"
[[ -f "$ICON" ]] || fail "vibrant More icon was not installed"
grep -Fq 'GRAYHAIRED-CONDITIONAL-OVERFLOW-STAGE13D' "$WATCHER" || fail "Stage 13D marker missing"

pass "Stage 13D conditional overflow trigger installed"
printf '[GRAYHAIRED-DRAWER13D] INFO: %s\n' "The More Desktop Items icon now appears only when real desktop items exceed visible grid capacity."
printf '[GRAYHAIRED-DRAWER13D] INFO: %s\n' "It uses a bright orange custom icon and a best-effort bottom-position hint."
printf '[GRAYHAIRED-DRAWER13D] INFO: %s\n' "Watcher log: $HOME/.cache/grayhaired-overflow-watch.log"
