import GLib from 'gi://GLib';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const GRAYHAIRED_APP_ID = 'tech.grayhaired.GrayHairedDesktop';
const ZORIN_WAYLAND_APP_ID = 'com.rastersoft.ding';
const ZORIN_TITLE_PREFIX = 'Desktop Icons ';

function valueOrNull(window, getter) {
    return typeof window[getter] === 'function' ? window[getter]() : null;
}

function isGrayHairedWindow(window) {
    const identifiers = [
        valueOrNull(window, 'get_wm_class'),
        valueOrNull(window, 'get_wm_class_instance'),
        valueOrNull(window, 'get_gtk_application_id'),
    ];
    return identifiers.some(identifier => identifier === GRAYHAIRED_APP_ID);
}

function isZorinDesktopIconsWindow(window) {
    // This is the same client identity and title convention observed in the
    // installed Zorin extension. Requiring both avoids title-only matching.
    return valueOrNull(window, 'get_gtk_application_id') === ZORIN_WAYLAND_APP_ID &&
        (valueOrNull(window, 'get_title') ?? '').startsWith(ZORIN_TITLE_PREFIX);
}

export default class GrayHairedDesktopLayerExtension extends Extension {
    enable() {
        this._signals = [];
        this._windowSignals = new Map();
        this._managed = null;
        this._idleId = 0;
        this._stacking = false;

        this._connect(global.window_manager, 'map', () => this._queueReconcile());
        this._connect(global.window_manager, 'destroy', () => this._queueReconcile());
        this._connect(global.workspace_manager, 'active-workspace-changed',
            () => this._queueReconcile());
        this._connect(Main.layoutManager, 'monitors-changed',
            () => this._queueReconcile());
        this._connect(Main.overview, 'showing', () => this._queueReconcile());
        this._connect(Main.overview, 'hidden', () => this._queueReconcile());

        this._queueReconcile();
        console.log('[GrayHaired Desktop Layer] development prototype enabled');
    }

    disable() {
        if (this._idleId) {
            GLib.source_remove(this._idleId);
            this._idleId = 0;
        }
        for (const [object, id] of this._signals)
            object.disconnect(id);
        this._signals = [];
        this._disconnectWindowSignals();
        this._restoreOrdinaryWindow();
        this._managed = null;
        console.log('[GrayHaired Desktop Layer] disabled; ordinary window restored');
    }

    _connect(object, signal, callback) {
        this._signals.push([object, object.connect(signal, callback)]);
    }

    _queueReconcile() {
        if (this._idleId)
            return;
        this._idleId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this._idleId = 0;
            this._reconcile();
            return GLib.SOURCE_REMOVE;
        });
    }

    _windows() {
        return global.get_window_actors()
            .map(actor => actor.get_meta_window())
            .filter(window => window !== null);
    }

    _reconcile() {
        const windows = this._windows();
        const grayWindow = windows.find(isGrayHairedWindow) ?? null;
        const iconWindows = windows.filter(isZorinDesktopIconsWindow);

        if (!grayWindow || iconWindows.length === 0) {
            this._disconnectWindowSignals();
            this._restoreOrdinaryWindow();
            if (grayWindow)
                console.log('[GrayHaired Desktop Layer] Zorin icon windows unavailable; fallback active');
            return;
        }

        if (!this._managed || this._managed.window !== grayWindow) {
            this._restoreOrdinaryWindow();
            this._managed = {
                window: grayWindow,
                frame: grayWindow.get_frame_rect(),
                monitor: grayWindow.get_monitor(),
                wasSticky: grayWindow.is_on_all_workspaces(),
            };
        }

        if (!this._supportsRelativeStacking(grayWindow, iconWindows)) {
            console.warn('[GrayHaired Desktop Layer] required Mutter stack APIs unavailable; fallback active');
            this._disconnectWindowSignals();
            this._restoreOrdinaryWindow();
            return;
        }

        this._watchWindows(grayWindow, iconWindows);
        this._applyDesktopGeometry(grayWindow);

        // Client windows remain in Mutter's authoritative window stack. Lower
        // GrayHaired first, then assign every icon window the consecutive slots
        // immediately above it. This runs only in response to lifecycle/state
        // events; there is no timer or continuous restacking loop.
        this._stacking = true;
        grayWindow.lower();
        const orderedIcons = global.display.sort_windows_by_stacking(iconWindows);
        const grayPosition = grayWindow.get_stack_position();
        orderedIcons.forEach((window, index) => {
            const wantedPosition = grayPosition + index + 1;
            if (window.get_stack_position() !== wantedPosition)
                window.set_stack_position(wantedPosition);
        });
        this._stacking = false;

        if (!this._hasRequiredOrder(grayWindow, orderedIcons)) {
            console.warn('[GrayHaired Desktop Layer] relative stack verification failed; fallback active');
            this._disconnectWindowSignals();
            this._restoreOrdinaryWindow();
        }
    }

    _applyDesktopGeometry(window) {
        const monitorIndex = Math.max(0, window.get_monitor());
        const monitor = Main.layoutManager.monitors[monitorIndex] ??
            Main.layoutManager.primaryMonitor;
        if (!monitor)
            return;
        if (!window.is_on_all_workspaces())
            window.stick();
        window.move_resize_frame(false, monitor.x, monitor.y, monitor.width, monitor.height);
    }

    _supportsRelativeStacking(grayWindow, iconWindows) {
        return typeof global.display.sort_windows_by_stacking === 'function' &&
            typeof grayWindow.lower === 'function' &&
            typeof grayWindow.get_stack_position === 'function' &&
            iconWindows.every(window =>
                typeof window.get_stack_position === 'function' &&
                typeof window.set_stack_position === 'function');
    }

    _hasRequiredOrder(grayWindow, iconWindows) {
        const relevant = global.display.sort_windows_by_stacking([
            grayWindow,
            ...iconWindows,
        ]);
        return relevant[0] === grayWindow &&
            relevant.slice(1).every((window, index) => window === iconWindows[index]);
    }

    _watchWindows(grayWindow, iconWindows) {
        const wanted = new Set([grayWindow, ...iconWindows]);
        for (const [window, id] of this._windowSignals) {
            if (!wanted.has(window)) {
                window.disconnect(id);
                this._windowSignals.delete(window);
            }
        }
        for (const window of wanted) {
            if (!this._windowSignals.has(window))
                this._windowSignals.set(window,
                    window.connect('raised', () => {
                        if (!this._stacking)
                            this._queueReconcile();
                    }));
        }
    }

    _disconnectWindowSignals() {
        if (!this._windowSignals)
            return;
        for (const [window, id] of this._windowSignals)
            window.disconnect(id);
        this._windowSignals.clear();
    }

    _restoreOrdinaryWindow() {
        if (!this._managed)
            return;
        const {window, frame, monitor, wasSticky} = this._managed;
        if (window.get_compositor_private() !== null) {
            if (!wasSticky && window.is_on_all_workspaces())
                window.unstick();
            window.move_to_monitor(monitor);
            window.move_resize_frame(false, frame.x, frame.y, frame.width, frame.height);
            window.raise();
        }
        this._managed = null;
    }
}
