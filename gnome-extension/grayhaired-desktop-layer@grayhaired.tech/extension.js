import GLib from 'gi://GLib';
import Meta from 'gi://Meta';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const GRAYHAIRED_APP_ID = 'tech.grayhaired.GrayHairedDesktop';
const ZORIN_WAYLAND_APP_ID = 'com.rastersoft.ding';
const ZORIN_TITLE_PREFIX = 'Desktop Icons ';
const DIAGNOSTIC_ONLY = true;
const WINDOW_API_NAMES = [
    'lower',
    'raise',
    'get_layer',
    'set_type',
    'stick',
    'unstick',
    'hide_from_window_list',
    'show_in_window_list',
    'get_stack_position',
    'set_stack_position',
];

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

function isGrayHairedDiagnosticCandidate(window) {
    return isGrayHairedWindow(window) ||
        valueOrNull(window, 'get_title') === 'GrayHaired Desktop';
}

function isZorinDiagnosticCandidate(window) {
    return (valueOrNull(window, 'get_title') ?? '').startsWith(ZORIN_TITLE_PREFIX);
}

export default class GrayHairedDesktopLayerExtension extends Extension {
    enable() {
        this._signals = [];
        this._windowSignals = new Map();
        this._managed = null;
        this._idleId = 0;
        this._stacking = false;
        this._loggedApiWindows = new WeakSet();
        this._loggedDetailedWindows = new WeakSet();
        this._lastOrderSummary = null;
        this._mappedDiagnosticWindows = new Set();

        this._connectAfter(global.window_manager, 'map', (_manager, actor) => {
            this._inspectMappedActor(actor);
            this._queueReconcile();
        });
        this._connect(global.window_manager, 'destroy', (_manager, actor) => {
            this._forgetMappedActor(actor);
            this._queueReconcile();
        });
        this._connect(global.workspace_manager, 'active-workspace-changed',
            () => this._queueReconcile());
        this._connect(Main.layoutManager, 'monitors-changed',
            () => this._queueReconcile());
        this._connect(Main.overview, 'showing', () => this._queueReconcile());
        this._connect(Main.overview, 'hidden', () => this._queueReconcile());

        this._logDisplayRuntimeApis();
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
        if (!DIAGNOSTIC_ONLY)
            this._restoreOrdinaryWindow();
        this._managed = null;
        this._mappedDiagnosticWindows.clear();
        console.log('[GrayHaired Desktop Layer] disabled');
    }

    _connect(object, signal, callback) {
        this._signals.push([object, object.connect(signal, callback)]);
    }

    _connectAfter(object, signal, callback) {
        this._signals.push([object, object.connect_after(signal, callback)]);
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

    _windowActors() {
        // Zorin filters Shell.Global.get_window_actors() to remove its desktop
        // windows. Read the compositor group directly, then merge the public
        // result for compatibility. Neither source is mutated or reordered.
        const actors = new Set();
        if (global.window_group &&
            typeof global.window_group.get_children === 'function') {
            for (const child of global.window_group.get_children()) {
                if (typeof child.get_meta_window === 'function')
                    actors.add(child);
            }
        }
        for (const actor of global.get_window_actors())
            actors.add(actor);
        return [...actors];
    }

    _windows() {
        const windows = new Set(this._windowActors()
            .map(actor => actor.get_meta_window())
            .filter(window => window !== null));
        for (const window of this._mappedDiagnosticWindows)
            windows.add(window);
        return [...windows];
    }

    _inspectMappedActor(actor) {
        if (!DIAGNOSTIC_ONLY || !actor ||
            typeof actor.get_meta_window !== 'function')
            return;
        const window = actor.get_meta_window();
        if (!window)
            return;
        const likelyGray = isGrayHairedDiagnosticCandidate(window);
        const likelyZorin = isZorinDiagnosticCandidate(window);
        const label = likelyGray
            ? 'MapGrayHairedCandidate'
            : likelyZorin
                ? 'MapZorinIconsCandidate'
                : 'MapOther';
        if (likelyGray || likelyZorin)
            this._mappedDiagnosticWindows.add(window);
        this._logWindowRuntimeApis(label, window, likelyGray || likelyZorin);
    }

    _forgetMappedActor(actor) {
        if (!actor || typeof actor.get_meta_window !== 'function')
            return;
        const window = actor.get_meta_window();
        if (window)
            this._mappedDiagnosticWindows.delete(window);
    }

    _reconcile() {
        const windows = this._windows();
        const grayWindow = windows.find(isGrayHairedWindow) ?? null;
        const iconWindows = windows.filter(isZorinDesktopIconsWindow);
        const grayCandidates = windows.filter(isGrayHairedDiagnosticCandidate);
        const iconCandidates = windows.filter(isZorinDiagnosticCandidate);

        grayCandidates.forEach(window =>
            this._logWindowRuntimeApis('GrayHairedCandidate', window, true));
        iconCandidates.forEach(window =>
            this._logWindowRuntimeApis('ZorinIconsCandidate', window, true));

        if (DIAGNOSTIC_ONLY) {
            this._logCurrentOrder(windows, grayCandidates, iconCandidates);
            return;
        }

        this._runStackingExperiment(grayWindow, iconWindows);
    }

    _runStackingExperiment(grayWindow, iconWindows) {

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

        // GNOME 46 exposes lower() and stack sorting, but no documented absolute
        // stack-position setters. Lower the icon windows first and GrayHaired
        // last: conventional Mutter lower() semantics should make the most
        // recently lowered window bottom-most. The sorted result below is the
        // authority; failure restores GrayHaired to ordinary-window behavior.
        this._stacking = true;
        const orderedIcons = global.display.sort_windows_by_stacking(iconWindows);
        orderedIcons.forEach(window => window.lower());
        grayWindow.lower();
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
            iconWindows.every(window => typeof window.lower === 'function');
    }

    _hasRequiredOrder(grayWindow, iconWindows) {
        const allWindows = global.display.sort_windows_by_stacking(this._windows());
        const grayIndex = allWindows.indexOf(grayWindow);
        const iconIndexes = iconWindows.map(window => allWindows.indexOf(window));
        if (grayIndex < 0 || iconIndexes.some(index => index <= grayIndex))
            return false;

        const highestIconIndex = Math.max(...iconIndexes);
        const managedWindows = new Set([grayWindow, ...iconWindows]);
        const ordinaryWindowsAreAbove = allWindows.every((window, index) => {
            if (managedWindows.has(window) || !this._isOrdinaryUserWindow(window))
                return true;
            return index > highestIconIndex;
        });
        const actor = grayWindow.get_compositor_private();
        return ordinaryWindowsAreAbove && actor !== null && actor.visible;
    }

    _isOrdinaryUserWindow(window) {
        if (typeof window.get_window_type !== 'function' ||
            window.get_window_type() !== Meta.WindowType.NORMAL)
            return false;
        return typeof window.is_skip_taskbar !== 'function' ||
            !window.is_skip_taskbar();
    }

    _logDisplayRuntimeApis() {
        const candidates = ['sort_windows_by_stacking'];
        const statuses = candidates.map(name =>
            `${name}=${typeof global.display[name]}`);
        const related = new Set();
        for (let object = global.display; object; object = Object.getPrototypeOf(object)) {
            for (const name of Object.getOwnPropertyNames(object)) {
                if (/(stack|restack|layer|lower|raise)/i.test(name) &&
                    typeof global.display[name] === 'function')
                    related.add(name);
            }
        }
        console.log(`[GrayHaired Desktop Layer][API] Meta.Display ${statuses.join(' ')} ` +
            `related=${[...related].sort().join(',') || '(none enumerated)'}`);
    }

    _logWindowRuntimeApis(label, window, includeDesktopDetails = false) {
        const loggedWindows = includeDesktopDetails
            ? this._loggedDetailedWindows
            : this._loggedApiWindows;
        if (loggedWindows.has(window))
            return;
        loggedWindows.add(window);
        this._loggedApiWindows.add(window);
        const methods = WINDOW_API_NAMES.map(name => `${name}=${typeof window[name]}`);
        const identity = [
            `wmClass=${valueOrNull(window, 'get_wm_class') ?? '(null)'}`,
            `wmClassInstance=${valueOrNull(window, 'get_wm_class_instance') ?? '(null)'}`,
            `gtkApplicationId=${valueOrNull(window, 'get_gtk_application_id') ?? '(null)'}`,
        ];
        if (includeDesktopDetails) {
            const workspace = valueOrNull(window, 'get_workspace');
            identity.push(
                `title=${JSON.stringify(valueOrNull(window, 'get_title') ?? '(null)')}`,
                `windowType=${valueOrNull(window, 'get_window_type') ?? '(null)'}`,
                `layer=${valueOrNull(window, 'get_layer') ?? '(null)'}`,
                `skipTaskbar=${valueOrNull(window, 'is_skip_taskbar') ?? '(null)'}`,
                `monitor=${valueOrNull(window, 'get_monitor') ?? '(null)'}`,
                `sticky=${valueOrNull(window, 'is_on_all_workspaces') ?? '(null)'}`,
                `workspace=${workspace && typeof workspace.index === 'function'
                    ? workspace.index()
                    : '(null)'}`,
            );
        }
        console.log(`[GrayHaired Desktop Layer][API] Meta.Window ${label} ` +
            `${identity.join(' ')} ${methods.join(' ')}`);
    }

    _logCurrentOrder(windows, grayCandidates, iconCandidates) {
        if (typeof global.display.sort_windows_by_stacking !== 'function')
            return;
        const graySet = new Set(grayCandidates);
        const iconSet = new Set(iconCandidates);
        const entries = global.display.sort_windows_by_stacking(windows)
            .map((window, index) => {
                if (graySet.has(window))
                    return `${index}:GrayHairedCandidate`;
                if (iconSet.has(window))
                    return `${index}:ZorinIconsCandidate`;
                if (this._isOrdinaryUserWindow(window))
                    return `${index}:NormalApplication`;
                return null;
            })
            .filter(entry => entry !== null);
        const summary = entries.join(' < ') || '(no relevant windows)';
        if (summary === this._lastOrderSummary)
            return;
        this._lastOrderSummary = summary;
        console.log(`[GrayHaired Desktop Layer][API] CurrentStack bottom-to-top=${summary}`);
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
