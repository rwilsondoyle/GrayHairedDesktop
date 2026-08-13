import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Meta from 'gi://Meta';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const GRAYHAIRED_APP_ID = 'tech.grayhaired.GrayHairedDesktop';
const ZORIN_WAYLAND_APP_ID = 'com.rastersoft.ding';
const ZORIN_TITLE_PREFIX = 'Desktop Icons ';
// Physical testing disproved both Meta.Window lowering and actor sibling
// reordering. Stacking remains observation-only.
const SAFE_INVESTIGATION_ONLY = true;
// Keep the proven ownership implementation, but do not launch its normal window
// while visually testing the independent Shell-owned actor layer.
const MANAGED_CLIENT_EXPERIMENT = false;
const SHELL_OWNED_LAYER_EXPERIMENT = true;
const MANAGED_CLIENT_CONFIG = 'managed-client-config.json';
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
    const identities = [
        valueOrNull(window, 'get_wm_class'),
        valueOrNull(window, 'get_wm_class_instance'),
        valueOrNull(window, 'get_gtk_application_id'),
    ];
    return identities.some(identity =>
        (identity ?? '').toLocaleLowerCase().includes('ding')) ||
        (valueOrNull(window, 'get_title') ?? '').startsWith(ZORIN_TITLE_PREFIX);
}

export default class GrayHairedDesktopLayerExtension extends Extension {
    enable() {
        this._enabled = true;
        this._signals = [];
        this._idleId = 0;
        this._loggedApiWindows = new WeakSet();
        this._loggedDetailedWindows = new WeakSet();
        this._loggedSpecialWindows = new WeakSet();
        this._lastOrderSummary = null;
        this._lastAllWindowsSummary = null;
        this._mappedDiagnosticWindows = new Set();
        this._lastActorHierarchySummary = null;
        this._managedClient = null;
        this._managedSubprocess = null;
        this._managedLaunchAttempted = false;
        this._shellOwnedTestActor = null;

        this._connectAfter(global.window_manager, 'map', (_manager, actor) => {
            this._inspectMappedActor(actor);
            this._queueReconcile();
        });
        const windowCreatedSignal = GObject.signal_lookup(
            'window-created', Meta.Display.$gtype);
        if (windowCreatedSignal) {
            this._connect(global.display, 'window-created', (_display, window) => {
                this._inspectCreatedWindow(window);
                this._queueReconcile();
            });
        }
        this._windowCreatedSignalAvailable = Boolean(windowCreatedSignal);
        this._connect(global.window_manager, 'destroy', (_manager, actor) => {
            this._forgetMappedActor(actor);
            this._queueReconcile();
        });
        this._connect(global.workspace_manager, 'active-workspace-changed',
            () => this._queueReconcile());
        this._connect(Main.layoutManager, 'monitors-changed',
            () => this._queueReconcile());

        this._logDisplayRuntimeApis();
        this._logShellLayerHierarchy();
        if (SHELL_OWNED_LAYER_EXPERIMENT)
            this._createShellOwnedLayerTest();
        this._queueReconcile();
        if (MANAGED_CLIENT_EXPERIMENT)
            this._launchManagedClientOnce();
        console.log('[GrayHaired Desktop Layer] development prototype enabled');
    }

    disable() {
        this._enabled = false;
        if (this._idleId) {
            GLib.source_remove(this._idleId);
            this._idleId = 0;
        }
        for (const [object, id] of this._signals)
            object.disconnect(id);
        this._signals = [];
        this._removeShellOwnedLayerTest();
        this._stopManagedClient();
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

    _listAllWindows() {
        return typeof global.display.list_all_windows === 'function'
            ? global.display.list_all_windows()
            : [];
    }

    _windows(listedWindows = this._listAllWindows()) {
        const windows = new Set();
        for (const window of listedWindows)
            windows.add(window);
        for (const window of this._windowActors()
            .map(actor => actor.get_meta_window())
            .filter(window => window !== null))
            windows.add(window);
        for (const window of this._mappedDiagnosticWindows)
            windows.add(window);
        return [...windows];
    }

    _inspectMappedActor(actor) {
        if (!actor ||
            typeof actor.get_meta_window !== 'function')
            return;
        const window = actor.get_meta_window();
        if (!window)
            return;
        this._inspectManagedWindow(window);
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

    _inspectCreatedWindow(window) {
        if (!window)
            return;
        const likelyGray = isGrayHairedDiagnosticCandidate(window);
        const likelyZorin = isZorinDiagnosticCandidate(window);
        if (likelyGray || likelyZorin)
            this._mappedDiagnosticWindows.add(window);
        const label = likelyGray
            ? 'CreatedGrayHairedCandidate'
            : likelyZorin
                ? 'CreatedZorinCandidate'
                : 'CreatedOther';
        this._logWindowRuntimeApis(label, window, likelyGray || likelyZorin);
    }

    _loadManagedClientConfig() {
        const configFile = this.dir.get_child(MANAGED_CLIENT_CONFIG);
        if (!configFile.query_exists(null))
            throw new Error(`${MANAGED_CLIENT_CONFIG} is absent`);
        const [ok, contents] = configFile.load_contents(null);
        if (!ok)
            throw new Error(`could not read ${MANAGED_CLIENT_CONFIG}`);
        const config = JSON.parse(new TextDecoder().decode(contents));
        if (!Array.isArray(config.argv) || config.argv.length === 0 ||
            config.argv.some(argument => typeof argument !== 'string' || !argument))
            throw new Error('config argv must be a non-empty string array');
        if (!GLib.path_is_absolute(config.argv[0]))
            throw new Error('config argv[0] must be an absolute executable path');
        if (config.cwd !== undefined &&
            (typeof config.cwd !== 'string' || !GLib.path_is_absolute(config.cwd)))
            throw new Error('config cwd must be an absolute path');
        if (config.environment !== undefined &&
            (typeof config.environment !== 'object' || Array.isArray(config.environment)))
            throw new Error('config environment must be an object');
        return config;
    }

    _launchManagedClientOnce() {
        if (this._managedLaunchAttempted)
            return;
        this._managedLaunchAttempted = true;
        const waylandClientType = typeof Meta.WaylandClient;
        const newSubprocessType = typeof Meta.WaylandClient?.new_subprocess;
        const newType = typeof Meta.WaylandClient?.new;
        console.log(`[GrayHaired Desktop Layer][ManagedClient] ` +
            `Meta.WaylandClient=${waylandClientType} ` +
            `new_subprocess=${newSubprocessType} new=${newType}`);
        if (!Meta.is_wayland_compositor() || waylandClientType === 'undefined') {
            console.warn('[GrayHaired Desktop Layer][ManagedClient] OWNERSHIP FAIL; ' +
                'GNOME 46 Wayland Meta.WaylandClient unavailable');
            return;
        }

        try {
            const config = this._loadManagedClientConfig();
            const launcher = new Gio.SubprocessLauncher({
                flags: Gio.SubprocessFlags.NONE,
            });
            if (config.cwd)
                launcher.set_cwd(config.cwd);
            for (const [name, value] of Object.entries(config.environment ?? {})) {
                if (typeof value !== 'string')
                    throw new Error(`environment value for ${name} must be a string`);
                launcher.setenv(name, value, true);
            }
            let apiPath;
            if (newSubprocessType === 'function') {
                this._managedClient = Meta.WaylandClient.new_subprocess(
                    global.context, launcher, config.argv);
                apiPath = 'new_subprocess';
            } else if (newType === 'function') {
                try {
                    this._managedClient = Meta.WaylandClient.new(launcher);
                    apiPath = 'new(launcher)+spawnv';
                } catch (launcherError) {
                    console.log('[GrayHaired Desktop Layer][ManagedClient] ' +
                        `new(launcher) failed: ${launcherError.message}`);
                    this._managedClient = Meta.WaylandClient.new(
                        global.context, launcher);
                    apiPath = 'new(global.context, launcher)+spawnv';
                }
            } else {
                throw new Error('no supported Meta.WaylandClient constructor');
            }
            console.log('[GrayHaired Desktop Layer][ManagedClient] ' +
                `spawnv=${typeof this._managedClient?.spawnv} ` +
                `get_subprocess=${typeof this._managedClient?.get_subprocess} ` +
                `owns_window=${typeof this._managedClient?.owns_window} ` +
                `hide_from_window_list=${typeof this._managedClient?.hide_from_window_list} ` +
                `show_in_window_list=${typeof this._managedClient?.show_in_window_list}`);
            if (apiPath === 'new_subprocess') {
                if (typeof this._managedClient?.get_subprocess !== 'function')
                    throw new Error('get_subprocess API unavailable');
                this._managedSubprocess = this._managedClient.get_subprocess();
            } else {
                if (typeof this._managedClient?.spawnv !== 'function')
                    throw new Error('spawnv API unavailable for old constructor path');
                this._managedSubprocess = this._managedClient.spawnv(
                    global.display, config.argv);
            }
            if (!this._managedSubprocess)
                throw new Error('managed launch returned no subprocess');
            if (typeof this._managedClient?.owns_window !== 'function') {
                console.warn('[GrayHaired Desktop Layer][ManagedClient] ' +
                    'OWNERSHIP FAIL; owns_window API unavailable');
                this._stopManagedClient();
                return;
            }
            console.log(`[GrayHaired Desktop Layer][ManagedClient] API path=${apiPath}`);
            console.log('[GrayHaired Desktop Layer][ManagedClient] GrayHaired process launched');
            const process = this._managedSubprocess;
            process.wait_async(null, (subprocess, result) => {
                try {
                    subprocess.wait_finish(result);
                } catch (error) {
                    console.warn(`[GrayHaired Desktop Layer][ManagedClient] wait failed: ${error.message}`);
                }
                if (this._managedSubprocess === process) {
                    this._managedSubprocess = null;
                    this._managedClient = null;
                    if (this._enabled)
                        console.log('[GrayHaired Desktop Layer][ManagedClient] process exited; no relaunch');
                }
            });
        } catch (error) {
            console.warn('[GrayHaired Desktop Layer][ManagedClient] OWNERSHIP FAIL; ' +
                `managed launch failed: ${error.message}`);
            this._stopManagedClient();
        }
    }

    _inspectManagedWindow(window) {
        if (!this._managedClient)
            return;
        if (typeof this._managedClient.owns_window !== 'function') {
            console.warn('[GrayHaired Desktop Layer][ManagedClient] ' +
                'OWNERSHIP FAIL; owns_window API unavailable');
            return;
        }
        let owned = false;
        try {
            owned = this._managedClient.owns_window(window);
        } catch (error) {
            console.warn(`[GrayHaired Desktop Layer][ManagedClient] ownership query failed: ${error.message}`);
            return;
        }
        const wmClass = valueOrNull(window, 'get_wm_class');
        const wmClassInstance = valueOrNull(window, 'get_wm_class_instance');
        const identityMatches = wmClass === GRAYHAIRED_APP_ID ||
            wmClassInstance === GRAYHAIRED_APP_ID;
        console.log(`[GrayHaired Desktop Layer][ManagedClient] mapped owned=${owned} ` +
            `wmClass=${wmClass ?? '(null)'} ` +
            `wmClassInstance=${wmClassInstance ?? '(null)'}`);
        if (owned && identityMatches) {
            console.log(`[GrayHaired Desktop Layer][ManagedClient] OWNERSHIP ` +
                'PASS');
        } else if (owned) {
            console.warn('[GrayHaired Desktop Layer][ManagedClient] ' +
                'OWNERSHIP FAIL; identity mismatch');
        } else if (identityMatches) {
            console.warn('[GrayHaired Desktop Layer][ManagedClient] OWNERSHIP FAIL; ' +
                'GrayHaired identity was not owned');
        }
    }

    _stopManagedClient() {
        // This reference is returned only by this extension's managed launch.
        // Never search by PID/name and never touch Zorin or other app instances.
        const process = this._managedSubprocess;
        this._managedSubprocess = null;
        this._managedClient = null;
        if (process) {
            process.force_exit();
            console.log('[GrayHaired Desktop Layer][ManagedClient] owned process terminated');
        }
    }

    _reconcile() {
        const listedWindows = this._listAllWindows();
        const windows = this._windows(listedWindows);
        const grayWindow = windows.find(isGrayHairedWindow) ?? null;
        const iconWindows = windows.filter(isZorinDesktopIconsWindow);
        const grayCandidates = windows.filter(isGrayHairedDiagnosticCandidate);
        const iconCandidates = windows.filter(isZorinDiagnosticCandidate);

        this._logAllWindowsSummary(listedWindows);

        grayCandidates.forEach(window =>
            this._logWindowRuntimeApis('GrayHairedCandidate', window, true));
        iconCandidates.forEach(window =>
            this._logWindowRuntimeApis('ZorinIconsCandidate', window, true));

        this._logCurrentOrder(windows, grayCandidates, iconCandidates);
        if (SAFE_INVESTIGATION_ONLY)
            this._logActorHierarchy(grayWindow, iconWindows);
    }

    _actorType(actor) {
        if (!actor)
            return '(null)';
        return actor.constructor?.$gtype?.name ??
            actor.constructor?.name ?? '(unknown)';
    }

    _actorCategory(actor, grayWindow, iconWindows) {
        if (!actor || typeof actor.get_meta_window !== 'function')
            return actor ? 'NonWindowActor' : '(none)';
        const window = actor.get_meta_window();
        if (window === grayWindow)
            return 'GrayHairedActor';
        if (iconWindows.includes(window))
            return 'ZorinIconsActor';
        if (window && this._isOrdinaryUserWindow(window))
            return 'NormalApplicationActor';
        return window ? 'OtherWindowActor' : 'NonWindowActor';
    }

    _actorDetails(label, actor, grayWindow, iconWindows) {
        if (!actor)
            return `${label}=unavailable`;
        const parent = typeof actor.get_parent === 'function'
            ? actor.get_parent()
            : null;
        const siblings = parent && typeof parent.get_children === 'function'
            ? parent.get_children()
            : [];
        const previous = typeof actor.get_previous_sibling === 'function'
            ? actor.get_previous_sibling()
            : null;
        const next = typeof actor.get_next_sibling === 'function'
            ? actor.get_next_sibling()
            : null;
        const parentName = parent && typeof parent.get_name === 'function'
            ? parent.get_name()
            : null;
        return `${label}=available actorType=${this._actorType(actor)} ` +
            `parentType=${this._actorType(parent)} ` +
            `parentName=${JSON.stringify(parentName ?? '(null)')} ` +
            `siblingIndex=${siblings.indexOf(actor)} ` +
            `previous=${this._actorCategory(previous, grayWindow, iconWindows)} ` +
            `next=${this._actorCategory(next, grayWindow, iconWindows)} ` +
            `actor.get_parent=${typeof actor.get_parent} ` +
            `actor.get_previous_sibling=${typeof actor.get_previous_sibling} ` +
            `actor.get_next_sibling=${typeof actor.get_next_sibling} ` +
            `parent.set_child_below_sibling=${typeof parent?.set_child_below_sibling} ` +
            `parent.set_child_above_sibling=${typeof parent?.set_child_above_sibling} ` +
            `parent.set_child_at_index=${typeof parent?.set_child_at_index}`;
    }

    _logActorHierarchy(grayWindow, iconWindows) {
        const grayActor = grayWindow &&
            typeof grayWindow.get_compositor_private === 'function'
            ? grayWindow.get_compositor_private()
            : null;
        const iconActors = iconWindows.map(window =>
            typeof window.get_compositor_private === 'function'
                ? window.get_compositor_private()
                : null);
        const grayParent = grayActor && typeof grayActor.get_parent === 'function'
            ? grayActor.get_parent()
            : null;
        const relationships = iconActors.map((actor, index) => {
            const parent = actor && typeof actor.get_parent === 'function'
                ? actor.get_parent()
                : null;
            return `grayAndZorin${index}.sameParent=${Boolean(grayParent && parent === grayParent)}`;
        });
        const lines = [
            this._actorDetails('GrayHaired', grayActor, grayWindow, iconWindows),
            ...iconActors.map((actor, index) =>
                this._actorDetails(`ZorinIcons${index}`, actor, grayWindow, iconWindows)),
            relationships.join(' ') || 'sameParent=(no Zorin actor)',
        ];
        const summary = lines.join(' | ');
        if (summary === this._lastActorHierarchySummary)
            return;
        this._lastActorHierarchySummary = summary;
        console.log(`[GrayHaired Desktop Layer][ActorDiagnostic] ${summary}`);
    }

    _isOrdinaryUserWindow(window) {
        if (typeof window.get_window_type !== 'function' ||
            window.get_window_type() !== Meta.WindowType.NORMAL)
            return false;
        return typeof window.is_skip_taskbar !== 'function' ||
            !window.is_skip_taskbar();
    }

    _logDisplayRuntimeApis() {
        const candidates = ['list_all_windows', 'sort_windows_by_stacking'];
        const statuses = candidates.map(name =>
            `${name}=${typeof global.display[name]}`);
        const related = new Set();
        for (let object = global.display; object; object = Object.getPrototypeOf(object)) {
            for (const name of Object.getOwnPropertyNames(object)) {
                if (/(window|list|stack|restack)/i.test(name) &&
                    typeof global.display[name] === 'function')
                    related.add(name);
            }
        }
        console.log(`[GrayHaired Desktop Layer][API] Meta.Display ${statuses.join(' ')} ` +
            `windowCreatedSignal=${this._windowCreatedSignalAvailable} ` +
            `related=${[...related].sort().slice(0, 30).join(',') || '(none enumerated)'}`);
    }

    _shellActorDescription(label, actor) {
        if (!actor)
            return `${label}=unavailable`;
        const parent = typeof actor.get_parent === 'function' ? actor.get_parent() : null;
        const siblings = parent && typeof parent.get_children === 'function'
            ? parent.get_children()
            : [];
        const name = typeof actor.get_name === 'function' ? actor.get_name() : null;
        return `${label}=available type=${this._actorType(actor)} ` +
            `name=${JSON.stringify(name ?? '(null)')} ` +
            `parentType=${this._actorType(parent)} siblingIndex=${siblings.indexOf(actor)} ` +
            `reactive=${actor.reactive ?? '(unavailable)'} ` +
            `visible=${actor.visible ?? '(unavailable)'} ` +
            `get_children=${typeof actor.get_children} add_child=${typeof actor.add_child} ` +
            `insert_child_at_index=${typeof actor.insert_child_at_index} ` +
            `remove_child=${typeof actor.remove_child} set_reactive=${typeof actor.set_reactive}`;
    }

    _logShellLayerHierarchy() {
        // Observation only: never create, insert, remove, or reorder an actor.
        const backgroundGroup = Main.layoutManager?._backgroundGroup ?? null;
        const layoutUiGroup = Main.layoutManager?.uiGroup ?? null;
        const mainUiGroup = Main.uiGroup ?? null;
        const actors = [
            ['backgroundGroup', backgroundGroup],
            ['layoutManager.uiGroup', layoutUiGroup],
            ['Main.uiGroup', mainUiGroup],
            ['window_group', global.window_group ?? null],
            ['top_window_group', global.top_window_group ?? null],
        ];
        for (const [label, actor] of actors)
            console.log(`[GrayHaired Desktop Layer][LayerHierarchy] ${
                this._shellActorDescription(label, actor)}`);

        const stage = global.stage ?? null;
        const stageChildren = stage && typeof stage.get_children === 'function'
            ? stage.get_children()
            : [];
        const known = new Map(actors.filter(([, actor]) => actor)
            .map(([label, actor]) => [actor, label]));
        const order = stageChildren.map((actor, index) =>
            `${index}:${known.get(actor) ?? this._actorType(actor)}`).join('<');
        console.log('[GrayHaired Desktop Layer][LayerHierarchy] ' +
            `stageType=${this._actorType(stage)} children=${stageChildren.length} ` +
            `order=${order || '(none)'}`);
        console.log('[GrayHaired Desktop Layer][LayerHierarchy] APIs ' +
            `layout.addChrome=${typeof Main.layoutManager?.addChrome} ` +
            `layout.trackChrome=${typeof Main.layoutManager?.trackChrome} ` +
            `layout.addTopChrome=${typeof Main.layoutManager?.addTopChrome} ` +
            `stage.add_child=${typeof stage?.add_child} ` +
            `stage.insert_child_at_index=${typeof stage?.insert_child_at_index}`);
    }

    _createShellOwnedLayerTest() {
        const parent = global.window_group ?? null;
        const backgroundGroup = Main.layoutManager?._backgroundGroup ?? null;
        const monitor = Main.layoutManager?.primaryMonitor ?? null;
        if (!parent || !backgroundGroup || !monitor ||
            typeof parent.get_children !== 'function' ||
            typeof parent.insert_child_at_index !== 'function' ||
            typeof backgroundGroup.get_parent !== 'function' ||
            backgroundGroup.get_parent() !== parent) {
            console.warn('[GrayHaired Desktop Layer][ShellOwnedLayer] FAIL; ' +
                'validated GNOME 46 background hierarchy unavailable');
            return;
        }

        const beforeChildren = parent.get_children();
        const backgroundIndex = beforeChildren.indexOf(backgroundGroup);
        if (backgroundIndex < 0) {
            console.warn('[GrayHaired Desktop Layer][ShellOwnedLayer] FAIL; ' +
                'backgroundGroup is not a child of window_group');
            return;
        }
        console.log('[GrayHaired Desktop Layer][ShellOwnedLayer] BEFORE ' +
            `backgroundType=${this._actorType(backgroundGroup)} ` +
            `backgroundIndex=${backgroundIndex} parentType=${this._actorType(parent)} ` +
            `childCount=${beforeChildren.length} testActor=absent`);

        const width = Math.max(320, Math.floor(monitor.width * 0.42));
        const height = Math.max(150, Math.floor(monitor.height * 0.24));
        const x = monitor.x + Math.floor((monitor.width - width) / 2);
        const y = monitor.y + Math.floor(monitor.height * 0.22);
        const actor = new St.BoxLayout({
            name: 'grayhaired-shell-layer-test',
            reactive: false,
            can_focus: false,
            style: 'background-color: rgba(38, 76, 112, 0.92); ' +
                'border: 5px solid rgba(220, 235, 248, 1); border-radius: 18px; ' +
                'padding: 28px;',
        });
        actor.add_child(new St.Label({
            text: 'GrayHaired Shell Layer Test',
            reactive: false,
            style: 'color: white; font-size: 28px; font-weight: bold;',
        }));
        actor.set_position(x, y);
        actor.set_size(width, height);
        this._shellOwnedTestActor = actor;

        parent.insert_child_at_index(actor, backgroundIndex + 1);
        const afterChildren = parent.get_children();
        const testActorIndex = afterChildren.indexOf(actor);
        const nextActor = afterChildren[testActorIndex + 1] ?? null;
        console.log('[GrayHaired Desktop Layer][ShellOwnedLayer] AFTER ' +
            `testActorType=${this._actorType(actor)} testActorIndex=${testActorIndex} ` +
            `backgroundIndex=${afterChildren.indexOf(backgroundGroup)} ` +
            `parentChildCount=${afterChildren.length} reactive=${actor.reactive} ` +
            `visible=${actor.visible} nextActor=${this._actorType(nextActor)}`);
        console.log('[GrayHaired Desktop Layer][ShellOwnedLayer] ' +
            'RESULT REQUIRES PHYSICAL VISUAL CONFIRMATION');
    }

    _removeShellOwnedLayerTest() {
        const actor = this._shellOwnedTestActor;
        this._shellOwnedTestActor = null;
        if (!actor)
            return;
        try {
            actor.destroy();
            console.log('[GrayHaired Desktop Layer][ShellOwnedLayer] ' +
                'extension-owned test actor removed');
        } catch (error) {
            console.warn(`[GrayHaired Desktop Layer][ShellOwnedLayer] cleanup failed: ${error.message}`);
        }
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
                `pid=${valueOrNull(window, 'get_pid') ?? '(null)'}`,
                `clientType=${valueOrNull(window, 'get_client_type') ?? '(null)'}`,
                `workspace=${workspace && typeof workspace.index === 'function'
                    ? workspace.index()
                    : '(null)'}`,
            );
        }
        console.log(`[GrayHaired Desktop Layer][API] Meta.Window ${label} ` +
            `${identity.join(' ')} ${methods.join(' ')}`);
    }

    _windowCategory(window) {
        if (isGrayHairedDiagnosticCandidate(window))
            return 'GrayHairedCandidate';
        if (isZorinDiagnosticCandidate(window))
            return 'ZorinCandidate';
        const windowType = valueOrNull(window, 'get_window_type');
        if (windowType === Meta.WindowType.NORMAL)
            return 'NormalApplication';
        if (windowType === Meta.WindowType.DESKTOP)
            return 'DesktopType';
        if (windowType === Meta.WindowType.DOCK)
            return 'DockType';
        return `Other(type=${windowType ?? 'unknown'})`;
    }

    _logAllWindowsSummary(windows) {
        if (typeof global.display.list_all_windows !== 'function')
            return;
        const categories = new Map();
        for (const window of windows) {
            const category = this._windowCategory(window);
            categories.set(category, (categories.get(category) ?? 0) + 1);
            if (category === 'GrayHairedCandidate' || category === 'ZorinCandidate')
                this._logWindowRuntimeApis(`ListAll${category}`, window, true);
            else if (category !== 'NormalApplication')
                this._logSpecialWindow(category, window);
        }
        const summary = [...categories]
            .sort(([left], [right]) => left.localeCompare(right))
            .map(([category, count]) => `${category}:${count}`)
            .join(',');
        const line = `count=${windows.length} categories=${summary || '(none)'}`;
        if (line === this._lastAllWindowsSummary)
            return;
        this._lastAllWindowsSummary = line;
        console.log(`[GrayHaired Desktop Layer][API] Meta.Display list_all_windows ${line}`);
    }

    _logSpecialWindow(category, window) {
        if (this._loggedSpecialWindows.has(window))
            return;
        this._loggedSpecialWindows.add(window);
        console.log('[GrayHaired Desktop Layer][API] Meta.Window Special ' +
            `category=${category} ` +
            `windowType=${valueOrNull(window, 'get_window_type') ?? '(null)'} ` +
            `layer=${valueOrNull(window, 'get_layer') ?? '(null)'} ` +
            `skipTaskbar=${valueOrNull(window, 'is_skip_taskbar') ?? '(null)'} ` +
            `monitor=${valueOrNull(window, 'get_monitor') ?? '(null)'} ` +
            `clientType=${valueOrNull(window, 'get_client_type') ?? '(null)'}`);
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


}
