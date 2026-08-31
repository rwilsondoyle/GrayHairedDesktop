#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
DRAWER="$BIN_DIR/grayhaired-desktop-items"
DESKTOP_FILE="$APP_DIR/grayhaired-desktop-items.desktop"

fail() {
    printf '[GRAYHAIRED-DRAWER13] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-DRAWER13] PASS: %s\n' "$*"
}

mkdir -p "$BIN_DIR" "$APP_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 is required"
fi

python3 - <<'PY' || exit 1
try:
    import gi
    gi.require_version('Gtk', '3.0')
    gi.require_version('Gio', '2.0')
    from gi.repository import Gtk, Gio
except Exception as exc:
    raise SystemExit(f'PyGObject/Gtk3 is unavailable: {exc}')
PY

cat > "$DRAWER" <<'PY'
#!/usr/bin/env python3
# GRAYHAIRED-DESKTOP-OVERFLOW-DRAWER-STAGE13
# GRAYHAIRED-DESKTOP-OVERFLOW-DRAWER-STAGE13B

import sys
from pathlib import Path

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gio', '2.0')
from gi.repository import Gtk, Gio, GLib

APP_ID = 'tech.grayhaired.DesktopItems'


class DesktopItemsWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title('More Desktop Items')
        self.set_default_size(520, 560)
        self.set_resizable(True)
        self.set_border_width(10)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.add(outer)

        title = Gtk.Label()
        title.set_markup('<b>More Desktop Items</b>')
        title.set_xalign(0)
        outer.pack_start(title, False, False, 0)

        help_label = Gtk.Label(
            label='Double-click any item to open it. This list shows everything in your Desktop folder.'
        )
        help_label.set_line_wrap(True)
        help_label.set_xalign(0)
        outer.pack_start(help_label, False, False, 0)

        toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        outer.pack_start(toolbar, False, False, 0)

        refresh = Gtk.Button.new_with_label('Refresh')
        refresh.connect('clicked', lambda *_: self.reload_items())
        toolbar.pack_start(refresh, False, False, 0)

        open_folder = Gtk.Button.new_with_label('Open Desktop Folder')
        open_folder.connect('clicked', lambda *_: self.open_desktop_folder())
        toolbar.pack_start(open_folder, False, False, 0)

        # icon, friendly display name, path, kind
        self.store = Gtk.ListStore(Gio.Icon, str, str, str)
        self.view = Gtk.TreeView(model=self.store)
        self.view.set_headers_visible(False)
        self.view.connect('row-activated', self.on_row_activated)

        icon_renderer = Gtk.CellRendererPixbuf()
        icon_col = Gtk.TreeViewColumn('', icon_renderer, gicon=0)
        icon_col.set_sizing(Gtk.TreeViewColumnSizing.FIXED)
        icon_col.set_fixed_width(46)
        self.view.append_column(icon_col)

        text_renderer = Gtk.CellRendererText()
        text_renderer.set_property('ellipsize', 3)
        text_col = Gtk.TreeViewColumn('Desktop item', text_renderer, text=1)
        text_col.set_expand(True)
        self.view.append_column(text_col)

        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroller.add(self.view)
        outer.pack_start(scroller, True, True, 0)

        self.status = Gtk.Label()
        self.status.set_xalign(0)
        outer.pack_start(self.status, False, False, 0)

        self.reload_items()
        self.show_all()

    def desktop_path(self):
        path = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP)
        if path:
            return Path(path)
        return Path.home() / 'Desktop'

    def desktop_launcher_info(self, path):
        """Return (friendly_name, icon) for a .desktop launcher when possible."""
        try:
            keyfile = GLib.KeyFile()
            keyfile.load_from_file(str(path), GLib.KeyFileFlags.NONE)
            name = keyfile.get_locale_string('Desktop Entry', 'Name', None)
            icon_name = None
            try:
                icon_name = keyfile.get_string('Desktop Entry', 'Icon')
            except GLib.Error:
                pass

            icon = None
            if icon_name:
                icon_path = Path(icon_name).expanduser()
                if icon_path.is_absolute() and icon_path.exists():
                    icon = Gio.FileIcon.new(Gio.File.new_for_path(str(icon_path)))
                else:
                    icon = Gio.ThemedIcon.new(icon_name)

            if not icon:
                icon = Gio.ThemedIcon.new('application-x-executable')

            return name or path.stem, icon
        except Exception:
            return path.stem, Gio.ThemedIcon.new('application-x-executable')

    def generic_info_for_path(self, path):
        try:
            gfile = Gio.File.new_for_path(str(path))
            info = gfile.query_info(
                'standard::display-name,standard::icon,standard::content-type,standard::type',
                Gio.FileQueryInfoFlags.NONE,
                None,
            )
            display_name = info.get_display_name() or path.name
            icon = info.get_icon()
            if icon is None:
                icon = Gio.ThemedIcon.new('folder' if path.is_dir() else 'text-x-generic')
            return display_name, icon
        except Exception:
            icon = Gio.ThemedIcon.new('folder' if path.is_dir() else 'text-x-generic')
            return path.name, icon

    def display_info_for_path(self, path):
        if path.is_file() and path.suffix.casefold() == '.desktop':
            return self.desktop_launcher_info(path)
        return self.generic_info_for_path(path)

    def reload_items(self):
        self.store.clear()
        desktop = self.desktop_path()
        if not desktop.exists():
            self.status.set_text(f'Desktop folder not found: {desktop}')
            return

        try:
            entries = sorted(
                [p for p in desktop.iterdir() if p.name not in ('.', '..')],
                key=lambda p: (not p.is_dir(), self.display_info_for_path(p)[0].casefold()),
            )
        except Exception as exc:
            self.status.set_text(f'Unable to read Desktop folder: {exc}')
            return

        for path in entries:
            display_name, icon = self.display_info_for_path(path)
            if path.is_dir():
                kind = 'Folder'
            elif path.suffix.casefold() == '.desktop':
                kind = 'Launcher'
            else:
                kind = 'File'

            self.store.append([
                icon,
                display_name,
                str(path),
                kind,
            ])

        count = len(entries)
        self.status.set_text(f'{count} desktop item' + ('' if count == 1 else 's'))

    def show_error(self, primary, secondary):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.CLOSE,
            text=primary,
        )
        dialog.format_secondary_text(str(secondary))
        dialog.run()
        dialog.destroy()

    def launch_desktop_file(self, path):
        try:
            app_info = Gio.DesktopAppInfo.new_from_filename(str(path))
            if app_info is None:
                raise RuntimeError('The desktop launcher could not be loaded.')
            context = Gio.AppLaunchContext()
            app_info.launch([], context)
        except Exception as exc:
            self.show_error('Could not launch application', exc)

    def launch_path(self, path, kind=None):
        target = Path(path)
        if kind == 'Launcher' or (target.is_file() and target.suffix.casefold() == '.desktop'):
            self.launch_desktop_file(target)
            return

        uri = Gio.File.new_for_path(path).get_uri()
        try:
            Gio.AppInfo.launch_default_for_uri(uri, None)
        except Exception as exc:
            self.show_error('Could not open desktop item', exc)

    def on_row_activated(self, view, tree_path, column):
        model = view.get_model()
        itr = model.get_iter(tree_path)
        path = model.get_value(itr, 2)
        kind = model.get_value(itr, 3)
        self.launch_path(path, kind)

    def open_desktop_folder(self):
        self.launch_path(str(self.desktop_path()), 'Folder')


class DesktopItemsApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        windows = self.get_windows()
        if windows:
            windows[0].present()
            return
        window = DesktopItemsWindow(self)
        window.present()


def main():
    # Register explicitly before entering the application loop. If another
    # instance already owns APP_ID, this process becomes the remote instance;
    # activating it raises/presents the existing primary window and exits.
    app = DesktopItemsApp()
    try:
        app.register(None)
    except GLib.Error as exc:
        print(f'Could not register More Desktop Items: {exc}', file=sys.stderr)
        return 1

    if app.get_is_remote():
        app.activate()
        return 0

    return app.run(sys.argv)


if __name__ == '__main__':
    raise SystemExit(main())
PY

chmod 0755 "$DRAWER"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=More Desktop Items
Comment=Open every item in your Desktop folder from a scrollable list
Exec=$DRAWER
Icon=user-desktop
Terminal=false
Categories=Utility;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

[[ -x "$DRAWER" ]] || fail "drawer executable was not created"
[[ -f "$DESKTOP_FILE" ]] || fail "application launcher was not created"
grep -Fq 'GRAYHAIRED-DESKTOP-OVERFLOW-DRAWER-STAGE13B' "$DRAWER" || fail "Stage 13B marker missing"
grep -Fq 'DesktopAppInfo.new_from_filename' "$DRAWER" || fail "desktop launcher handling missing"
grep -Fq 'app.get_is_remote()' "$DRAWER" || fail "explicit single-instance handling missing"

pass "Stage 13B desktop overflow drawer installed"
printf '[GRAYHAIRED-DRAWER13] INFO: launch with: %s\n' "$DRAWER"
printf '[GRAYHAIRED-DRAWER13] INFO: a second launch should present the existing window rather than create another\n'
printf '[GRAYHAIRED-DRAWER13] INFO: .desktop launchers now use friendly names, real icons, and application launching\n'
printf '[GRAYHAIRED-DRAWER13] INFO: this experiment does not modify DING, WebKit, or desktopGrid.js\n'
