#!/usr/bin/env gjs

/*
 * Standalone GTK3/GJS Wayland proof-of-concept for a transparent/input-hole
 * desktop-like window. This does not modify DING or My Desktop.
 */

'use strict';

imports.gi.versions.Gtk = '3.0';
imports.gi.versions.Gdk = '3.0';

const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const Cairo = imports.cairo;

const LEFT_HOLE_WIDTH = 220;
const TEST_FILL_RED = 0.20;
const TEST_FILL_GREEN = 0.23;
const TEST_FILL_BLUE = 0.27;
const TEST_FILL_ALPHA = 0.97;

Gtk.init(null);

const display = Gdk.Display.get_default();
if (!display) {
    printerr('No GDK display available.');
    imports.system.exit(2);
}

const displayName = display.get_name();
print(`[GTK-HOLE] Display: ${displayName}`);

const window = new Gtk.Window({
    title: 'GTK3 Wayland Input Hole Test',
    decorated: false,
    resizable: false,
});

window.set_app_paintable(true);
window.set_keep_below(true);
window.stick();

const screen = window.get_screen();
if (screen) {
    const visual = screen.get_rgba_visual();
    if (visual) {
        window.set_visual(visual);
        print('[GTK-HOLE] RGBA visual enabled.');
    } else {
        print('[GTK-HOLE] WARNING: no RGBA visual available.');
    }
}

window.connect('delete-event', () => {
    Gtk.main_quit();
    return false;
});

window.connect('key-press-event', (widget, event) => {
    const keyval = event.get_keyval()[1];
    const state = event.get_state()[1];
    const ctrl = (state & Gdk.ModifierType.CONTROL_MASK) !== 0;
    const alt = (state & Gdk.ModifierType.MOD1_MASK) !== 0;

    if (ctrl && alt && (keyval === Gdk.KEY_q || keyval === Gdk.KEY_Q)) {
        print('[GTK-HOLE] Exit shortcut pressed.');
        Gtk.main_quit();
        return true;
    }

    return false;
});

window.connect('draw', (widget, cr) => {
    const allocation = widget.get_allocation();

    // Clear the whole surface to transparent.
    cr.setOperator(Cairo.Operator.CLEAR);
    cr.paint();

    // Draw only the area to the right of the transparent icon zone.
    cr.setOperator(Cairo.Operator.OVER);
    cr.rectangle(
        LEFT_HOLE_WIDTH,
        0,
        Math.max(0, allocation.width - LEFT_HOLE_WIDTH),
        allocation.height
    );
    cr.setSourceRGBA(
        TEST_FILL_RED,
        TEST_FILL_GREEN,
        TEST_FILL_BLUE,
        TEST_FILL_ALPHA
    );
    cr.fill();

    return false;
});

window.connect('realize', () => {
    const gdkWindow = window.get_window();
    if (!gdkWindow) {
        print('[GTK-HOLE] WARNING: no GdkWindow after realize.');
        return;
    }

    const allocation = window.get_allocation();

    // Only the area to the right of LEFT_HOLE_WIDTH should receive input.
    const inputRegion = new Cairo.Region();
    inputRegion.unionRectangle({
        x: LEFT_HOLE_WIDTH,
        y: 0,
        width: Math.max(1, allocation.width - LEFT_HOLE_WIDTH),
        height: Math.max(1, allocation.height),
    });

    try {
        gdkWindow.input_shape_combine_region(inputRegion, 0, 0);
        print(`[GTK-HOLE] Input region applied; left ${LEFT_HOLE_WIDTH}px excluded.`);
    } catch (e) {
        printerr(`[GTK-HOLE] input_shape_combine_region failed: ${e.message}`);
    }
});

window.connect('button-press-event', (widget, event) => {
    const [, x, y] = event.get_coords();
    print(`[GTK-HOLE] WINDOW CLICK x=${Math.round(x)} y=${Math.round(y)}`);
    return false;
});

// Size the test to the primary monitor's full geometry. Under Wayland the
// compositor owns placement, so maximize rather than attempting X11-style move.
window.set_default_size(1366, 768);
window.maximize();
window.show_all();

print('[GTK-HOLE] Test running.');
print(`[GTK-HOLE] Left ${LEFT_HOLE_WIDTH}px should be visually transparent and click-through.`);
print('[GTK-HOLE] Ctrl+Alt+Q closes the test.');

Gtk.main();
