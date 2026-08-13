# GNOME Shell Desktop Integration Feasibility

## Current status

This investigation remains open. Real testing has proved that pure Qt window
hints do not provide the required GNOME desktop layer, but it has **not** proved
that cooperation with the installed Zorin desktop-icon extension is impossible.
A GNOME Shell prototype is included as manually installed development source.
The lower-only Phase 2 experiment and the subsequent direct actor sibling-order
experiment both failed safely on the physical Wayland target. The prototype is
back in `SAFE_INVESTIGATION_ONLY = true` mode: no stacking experiment is active.
Physical testing now proves managed-process ownership through
`Meta.WaylandClient`, but the subsequent window-list semantics test also failed
visually. The prototype performs ownership diagnostics without window mutation.
Read-only source inspection found no supported Zorin cooperation point. The
remaining Shell-owned visual-layer direction currently depends on private layer
placement and an unproven external frame/input bridge, so it is not suitable for
Version 1.0 at present.
Normal application startup still installs or enables nothing. The
project remains version `0.9.0`, and a safe Zorin/Wayland Desktop Mode remains a
pre-Version 1.0 investigation requirement.

The required order is:

```text
GNOME wallpaper
GrayHaired Desktop live Desktop Website
Zorin Desktop Icons
normal application windows
Zorin taskbar, panel, and menus
```

GrayHaired Desktop must remain interactive without becoming an icon manager,
hiding real icons, or becoming an ordinary maximized application.

## Confirmed target runtime

Information collected on the real target computer establishes this baseline:

| Item | Confirmed value |
| --- | --- |
| Operating system | Zorin OS 18.1 |
| GNOME Shell | 46.0 |
| Sessions physically tested | X11 feasibility trials and native Wayland diagnostics/experiments |
| Desktop environment | `zorin:GNOME` |
| Desktop-icon extension UUID | `zorin-desktop-icons@zorinos.com` |
| Name | Zorin Desktop Icons |
| State | ACTIVE |
| Installed path | `/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com` |
| Declared Shell versions | 46, 47, 48, 49, and 50 |
| Description | “Adds icons to the desktop. Fork of the original Desktop Icons extension, with several enhancements.” |

Other active or relevant Zorin integration includes `zorin-taskbar@zorinos.com`,
`zorin-menu@zorinos.com`, `zorin-tiling-shell@zorinos.com`, and
`zorin-appindicator@zorinos.com`. Any prototype must preserve their Shell chrome
and must not assume upstream GNOME’s unmodified panel layout.

The provider identity is **Zorin Desktop Icons**, not an upstream DING UUID.
However, the installed files contain many source headers reading “DING: Desktop
Icons New Generation for GNOME Shell.” The implementation therefore contains
substantial DING-derived code even though Zorin's metadata describes a fork of
the original Desktop Icons extension. Neither fact supersedes the other: the
provider is Zorin's extension, its implementation has DING ancestry, and the
exact Zorin modifications must be established from the installed source.

The investigation began with X11 feasibility trials, which established the pure
Qt failure modes. Later physical tests ran in a native Wayland session with Qt's
`wayland` platform. Those tests verified application and Zorin window identities,
`Meta.Display.list_all_windows()`, exposed `Meta.Window` APIs, compositor actor
hierarchy, and the failures of both `lower()` and direct actor sibling ordering.
Wayland remains the primary product requirement; users must not be required to
switch permanently to X11.

## Read-only inspection of Zorin Desktop Icons

Run this from the repository on the target Zorin computer:

```bash
./scripts/collect-zorin-desktop-icons-info.sh \
  | tee zorin-desktop-icons-info.txt
```

The script has one fixed inspection root:

```text
/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com
```

It reads only that directory and reports:

- up to 240 lines of `metadata.json`, including `shell-version` and extension
  version fields when present;
- a sorted, depth-limited file/directory inventory;
- a bounded list of JavaScript files; and
- at most 320 match/context lines for background, desktop, window, actor,
  monitor, work-area, layout-manager, chrome, `Meta.Window`, Shell window-group,
  actor ordering, lowering/raising/stacking, `desktopManager`, and `desktopGrid`
  terms.

It does not accept an alternate path and does not write to the extension. It does
not modify, copy, patch, install, remove, enable, disable, or restart anything.
The general `collect-gnome-info.sh` remains useful for session facts, while this
first-stage script provides a broad source inventory for the confirmed provider.

The first broad report did not answer the actor-versus-window question. Matches
from unrelated application files, especially `app/autoAr.js`, consumed its global
320-line context limit before the most important Shell integration files were
printed. It confirmed the provider and DING-derived headers, but it is not
architecture evidence for A, B, or C below.

Use the more focused second-stage collector:

```bash
./scripts/collect-zorin-shell-layer-info.sh \
  | tee zorin-shell-layer-info.txt
```

This read-only script prints bounded opening sections and per-file contextual
matches from `extension.js`, `gnomeShellOverride.js`, `visibleArea.js`, and
`emulateX11WindowType.js`. It searches only relevant portions of `app/ding.js`,
`app/desktopManager.js`, and `app/desktopGrid.js`. A separate limit for every
file prevents a noisy early file from hiding later Shell integration evidence.
The fixed root and path-containment check prevent it from reading a supplied
alternate directory or following a target file outside the installed extension.

## Confirmed Zorin window architecture

The targeted source report establishes the client-window model:

1. a separate desktop application renders the visible icons in client windows;
2. the Shell extension obtains each client window as a `Meta.Window` from its
   window actor and manages it on `global.window_manager`'s `map` lifecycle;
3. Wayland support in `emulateX11WindowType.js` reproduces the desktop-window
   semantics that the X11 implementation receives from its window type;
4. the extension verifies its own Wayland client identity before applying the
   title convention—windows beginning with `Desktop Icons ` are not accepted by
   title alone;
5. those windows are kept at the bottom with `Meta.Window.lower()`, shown on all
   workspaces, hidden from normal window lists, fixed, and positioned per monitor;
   and
6. `gnomeShellOverride.js` excludes them from normal Activities/window-list and
   workspace-animation behavior.

This proves that GNOME Shell 46 can give recognized, trusted Wayland client
windows desktop behavior without weakening Wayland. It materially changes the
feasibility result: an interactive client-window Desktop Mode is not
architecturally ruled out. GrayHaired Desktop must retain its own identity; it
must never use the `Desktop Icons ` title convention or impersonate Zorin's
Wayland client.

The remaining question is narrower: can Mutter maintain GrayHaired Desktop at
the bottom of the client-window stack, with all Zorin icon windows in consecutive
positions directly above it and all ordinary windows above those? Shell wallpaper
actors remain below Mutter client windows, and Shell chrome remains separately
above them, but the exact relative client ordering still needs physical GNOME 46
validation through map/remap, focus, Overview, Show Desktop, workspaces, icon-
window recreation, and monitor changes.

## GNOME Shell 46 integration constraints

Any example or prototype for this target must use GNOME 46’s ES-module extension
architecture, not pre-GNOME-45 legacy imports. A minimal future layout would be:

```text
grayhaired-desktop-layer@grayhaired.tech/
  metadata.json
  extension.js
```

`metadata.json` would declare only actually tested Shell versions, initially
`"shell-version": ["46"]`. `extension.js` would import the GNOME 46 extension
base class from `resource:///org/gnome/shell/extensions/extension.js` and Shell
modules through `resource:///org/gnome/shell/ui/...`. Its `enable()` method would
inspect existing relevant objects and connect narrowly scoped signals. Its
`disable()` method would disconnect every handler and undo every change it owns.
It must never terminate Zorin Desktop Icons or the Python application.

Authoritative GNOME references for the eventual implementation review are:

- [GNOME Shell extension anatomy and metadata](https://gjs.guide/extensions/development/creating.html)
- [GNOME 45+ ES-module porting guide](https://gjs.guide/extensions/upgrading/gnome-shell-45.html)
- [Mutter `Meta.Window` API](https://gnome.pages.gitlab.gnome.org/mutter/meta/class.Window.html)
- [GNOME Shell `Shell.WindowTracker` API](https://gnome.pages.gitlab.gnome.org/gnome-shell/shell/class.WindowTracker.html)

GNOME APIs being callable does not by itself make the Zorin-relative ordering a
supported or durable contract. Installed Zorin source and physical behavior are
both required evidence.

## Identifying the existing PySide6 surface

The application now configures `tech.grayhaired.GrayHairedDesktop` before the
first native window. On the tested Qt Wayland build, that value appears through
the Meta.Window WM class and instance fields rather than the GTK application-ID
field. `QT_WM_CLASS` supplies the X11 resource class. Existing QSettings
organization/application keys are unchanged, so this compositor identity does
not relocate user preferences.

Native-Wayland diagnostics physically verified this PySide6/Qt build as:

```text
wmClass=tech.grayhaired.GrayHairedDesktop
wmClassInstance=tech.grayhaired.GrayHairedDesktop
gtkApplicationId=(null)
```

The development extension therefore requires an exact WM class or instance
match for GrayHaired Desktop. It does not require
`get_gtk_application_id()` and never identifies GrayHaired Desktop by title
alone.

| Identifier | Role | Limitation |
| --- | --- | --- |
| Wayland WM class/instance | Physically verified native-Wayland identity | Exact value is `tech.grayhaired.GrayHairedDesktop`. |
| X11 `WM_CLASS` | Preferred native-X11 identity | Does not define native Wayland identity. |
| `get_gtk_application_id()` | Optional diagnostic value | Observed as null in the tested PySide6/Qt Wayland build. |
| title | Diagnostic secondary signal only | Mutable, localizable, and collision-prone. |
| PID | Correlation during one run | Changes each launch and must not be persisted as identity. |

No extension may manage a window solely because its title resembles GrayHaired
Desktop. Identification is necessary for integration, but it does not grant a
layering capability.

## Development-only relative-stacking prototype

The confirmed client-window architecture is strong enough for a small source-only
prototype under `gnome-extension/`. It independently uses GNOME 46 APIs rather
than copying Zorin/DING implementation code. It contains no network renderer and
does not modify or import Zorin's extension.

Prototype source and deferred manual installation/removal steps are in
[`gnome-extension/README.md`](../gnome-extension/README.md). Nothing in normal
application startup installs or enables it.

Phase 1 and both physical stacking experiments are complete, with both stacking
approaches recorded as insufficient below. The source now defaults to
`SAFE_INVESTIGATION_ONLY = true`; no stacking experiment is active, and normal
application startup still does not install or enable the extension.

### Confirmed native-Wayland Phase 1 evidence

The safe diagnostic ran on Zorin OS 18.1, GNOME Shell 46.0, native Wayland, with
Qt's `wayland` platform. It confirmed that
`global.display.list_all_windows()` and
`global.display.sort_windows_by_stacking()` are functions and that the
`Meta.Display::window-created` signal is available in the live Shell context.
`list_all_windows()` was the discovery API that exposed the already-running Zorin
window hidden from Shell actor-list presentation APIs.

GrayHaired Desktop was observed as:

```text
wmClass=tech.grayhaired.GrayHairedDesktop
wmClassInstance=tech.grayhaired.GrayHairedDesktop
gtkApplicationId=(null)
title="GrayHaired Desktop"
windowType=0
layer=8
skipTaskbar=false
monitor=0
sticky=false
```

The production GrayHaired matcher therefore uses the exact WM class or instance;
it does not require a GTK application ID and never uses the title alone.

Zorin Desktop Icons was observed as:

```text
wmClass=gjs
wmClassInstance=gjs
gtkApplicationId=com.rastersoft.ding
title="Desktop Icons 1"
windowType=0
layer=2
skipTaskbar=true
monitor=0
sticky=false
```

The production-quality Zorin matcher requires both
`gtkApplicationId == "com.rastersoft.ding"` and the `Desktop Icons ` title
prefix. The title is not sufficient by itself.

The live `Meta.Window` exposed `lower`, `raise`, `get_layer`, `stick`, and
`unstick`. It did not expose `set_type`, either window-list mutation method, or
either stack-position method. No unavailable method is used. The observed
bottom-to-top order before mutation was:

```text
Zorin Desktop Icons
GrayHaired Desktop
ordinary application windows
```

This was an ordinary starting state, not a Desktop Mode result.

### Confirmed Phase 2 failure

The first physical Phase 2 test ran on the same native-Wayland target. Discovery
found one Zorin icon window and GrayHaired Desktop. The observed relevant order
was:

```text
Zorin Desktop Icons
ordinary application windows
GrayHaired Desktop
```

Calling only `grayWindow.lower()` produced exactly the same order. Verification
failed, and the fallback restored GrayHaired Desktop to ordinary behavior. This
confirms that `Meta.Window.lower()` by itself is insufficient in the tested
Zorin/GNOME Wayland compositor state. No repeated calls, delay, polling, or Zorin
window mutation is justified by this result.

### Confirmed actor hierarchy

The next native-Wayland diagnostic obtained both actors through the proven
`Meta.Window.get_compositor_private()` relationship:

- GrayHaired Desktop: `MetaWindowActorWayland`;
- Zorin Desktop Icons: `MetaWindowActorWayland`;
- common parent type: `MetaWindowGroup`;
- exact parent identity: `grayAndZorin0.sameParent=true`.

Both actors expose `get_parent`, `get_previous_sibling`, and
`get_next_sibling`. Their shared parent exposes `set_child_below_sibling`,
`set_child_above_sibling`, and `set_child_at_index`.

One snapshot placed GrayHaired at sibling index 1 with the Zorin actor next, and
Zorin at index 2 with GrayHaired previous. Thus the actor hierarchy already had
GrayHaired below Zorin even though `sort_windows_by_stacking()` reported Zorin
below GrayHaired. This confirms that visual Clutter actor order and Meta.Window
stack order are not necessarily identical on this setup.

### Confirmed actor-order failure

The physical actor experiment changed the reported order from
`ZorinIcons<GrayHaired` to `GrayHaired<ZorinIcons`. The Meta.Window order did not
change, and visually GrayHaired remained above and obscured the actual desktop
icons. The Zorin dock/panel remained above GrayHaired. Verification failed and
the saved sibling relationship was restored successfully.

Consequently, neither `Meta.Window.lower()` nor direct `MetaWindowActorWayland`
sibling ordering controls the required visible relationship on this tested
Mutter/Wayland compositor. More permutations, delays, repeated restacking, and
polling would fight the compositor rather than prove a maintainable design. The
prototype is back in `SAFE_INVESTIGATION_ONLY = true` mode and contains no live
window or actor mutation.

### Zorin's managed Wayland client mechanism

Installed-source evidence shows a materially different design from an ordinary
third-party window:

1. the Shell extension retains a Wayland-client ownership object alongside the
   separately launched DING-derived desktop application;
2. its map-time handler receives a compositor actor, obtains the associated
   `Meta.Window`, and asks Zorin's wrapper to confirm client ownership;
3. `emulateX11WindowType.js` attaches desktop-window state to accepted windows,
   applies the `Desktop Icons ` role, monitor placement, bottom behavior, and
   all-workspace semantics; and
4. the same managed client participates in `hide_from_window_list()` and
   `show_in_window_list()` handling. Lifecycle code clears the Wayland-client
   reference when the desktop process is killed or relaunched rather than
   retaining stale ownership state.

The enhanced collector established the missing implementation detail. Zorin's
`LaunchSubprocess` wrapper creates a `Gio.SubprocessLauncher`; on Wayland its
privileged ownership primitive is Mutter's `Meta.WaylandClient`. The GNOME 46
path is:

```javascript
Meta.WaylandClient.new_subprocess(global.context, launcher, argv)
```

Zorin then obtains the launched process with `get_subprocess()`. Its
`launchDesktop()` constructs the `app/ding.js` argument vector, calls the local
wrapper's `spawnv(argv)`, and supplies that wrapper to the desktop-window
emulator. Older source branches use `Meta.WaylandClient.new(...)` followed by
`spawnv(global.display, argv)`; the ownership prototype now uses exactly those
older paths because physical GNOME 46 testing found `new_subprocess` unavailable.

Thus the Zorin wrapper is lifecycle glue, not the ownership primitive. Its
`query_window_belongs_to(window)` method delegates to raw
`Meta.WaylandClient.owns_window(window)`, which supplies the trusted
process/window association. This makes an independently owned GrayHaired
Wayland subprocess technically plausible from a GNOME Shell extension, but it
does not prove relative ordering with Zorin's separate desktop client. The
Zorin/DING source is used only as architectural evidence; no GPL implementation
is copied, and the prototype's small lifecycle is independently written against
the observed Mutter API.

### Managed-client ownership experiment

`MANAGED_CLIENT_EXPERIMENT = true` enables one development-only ownership test;
`SAFE_INVESTIGATION_ONLY = true` continues to prohibit stacking changes. The
extension reads a manually created `managed-client-config.json` beside its source
and requires an absolute executable path. The documented configuration launches
the repository virtual environment's Python interpreter directly with
`-m grayhaired_desktop.app`, an explicit working directory, and `PYTHONPATH`.
It does not invoke a shell or `scripts/run.sh`, so there is no wrapper process
whose fork/exec behavior could make the ownership result ambiguous.

The first native-Wayland ownership run failed safely before launch because the
physical GNOME Shell 46 runtime reported `Meta.WaylandClient.new_subprocess` as
undefined. A second physical run established the older API surface:

```text
Meta.WaylandClient=function
new_subprocess=undefined
new=function
spawnv=function
get_subprocess=undefined
query_window_belongs_to=undefined
hide_from_window_list=function
show_in_window_list=function
```

That run created the old client and launched the managed process, but failed
safely because the prototype incorrectly required the Zorin wrapper method
`query_window_belongs_to()` on the raw client. Its retained subprocess was
terminated safely. Installed source confirms that the raw GNOME 46 ownership
method is `owns_window(window)`.

The corrected experiment then passed physically on the Inspiron-3147 native
Wayland session. `new(launcher)` was rejected because GNOME 46 required at least
two arguments; `new(global.context, launcher)` succeeded. The resulting client
exposed `spawnv` and `owns_window`, launched GrayHaired through the configured
Python 3.12.3 process, and returned true for its mapped window. The window
preserved both exact WM identity fields as
`tech.grayhaired.GrayHairedDesktop`. Closing the window manually produced the
expected `process exited; no relaunch` lifecycle event; this was not a crash.

Managed-client ownership is therefore a **physically validated primitive** on
this GNOME Shell 46 target. Relative stacking below Zorin Desktop Icons remains
unproven, and full Desktop Mode remains unresolved.

The verified ownership implementation creates a fresh `Gio.SubprocessLauncher`
and selects only among the
installed-source-supported paths, in this order:

1. `Meta.WaylandClient.new_subprocess(global.context, launcher, argv)` when it is
   callable;
2. otherwise `Meta.WaylandClient.new(launcher)`, followed by
   `client.spawnv(global.display, argv)`; or
3. if that constructor signature throws,
   `Meta.WaylandClient.new(global.context, launcher)`, followed by the same
   managed `spawnv`.

It logs the selected path and live availability of `owns_window`, `spawnv`,
`get_subprocess`, `hide_from_window_list`, and
`show_in_window_list`. There is no ordinary `Gio.Subprocess` fallback: if all
source-demonstrated managed paths fail, nothing is launched and there is no
retry.

The existing map signal supplies each new actor's `Meta.Window`. Ownership
requires both `owns_window(window) === true` and an exact WM class or
instance match for `tech.grayhaired.GrayHairedDesktop` before logging
`OWNERSHIP PASS`. It logs no Desktop Website title or content. The window remains
an ordinary application window: no lower, raise, actor reorder, resize, monitor,
workspace, type, focus, or Zorin operation occurs.

The returned subprocess is retained directly. Disablement calls `force_exit()`
only on that retained subprocess; it never searches by PID, name, title, or WM
class and therefore cannot terminate Zorin Desktop Icons or a separately started
GrayHaired instance. Natural exit is logged without retry or automatic relaunch.
Missing configuration/API, launch failure, ownership failure, or identity failure
stops the experiment safely without any stacking action.

### Confirmed managed desktop-semantics failure

The one-shot `Meta.WaylandClient.hide_from_window_list(grayWindow)` experiment
was physically tested on the Inspiron-3147 Wayland session after ownership and
exact identity passed. It changed GrayHaired's `skipTaskbar` value from false to
true, while window type remained 0, layer remained 2, and the relevant
Meta.Window order remained
`ZorinIcons<NormalApplication<NormalApplication<GrayHaired`. Zorin's icon window
also remained type 0 and layer 2.

Visual testing confirmed that real Zorin icons remained underneath GrayHaired.
GrayHaired stayed visible and usable, ordinary application windows stayed above
it, and the panel/dock stayed above everything. Actor ordering likewise did not
establish the required visual result. Therefore `hide_from_window_list()` only
changed window-list/taskbar semantics and is rejected as a Desktop Mode layer.
The live mutation path has been removed; managed ownership now returns to
observation-only behavior.

Three independent mechanisms are physically disproven on this target:

1. `Meta.Window.lower()`;
2. direct `MetaWindowActorWayland` sibling reordering; and
3. `Meta.WaylandClient.hide_from_window_list()`.

Combining or repeatedly retrying those failed operations is not justified.

API classification:

- **Documented Mutter API:** `Meta.Display.list_all_windows()`,
  `sort_windows_by_stacking()`, `window-created`, and the runtime-exposed
  `Meta.Window` read methods. These provide discovery and observation, not the
  missing relative desktop layer.
- **Mutter API used from GNOME Shell:** `Meta.WaylandClient`; the physical target
  lacks `new_subprocess()` but exposes `new(...)`, `spawnv(...)`, and window-list
  methods. Installed source establishes `owns_window(...)` as the raw ownership
  interface, which physical testing has verified.
- **Zorin-specific wrapper:** `LaunchSubprocess` builds launcher/process lifecycle
  policy around the Mutter primitive; that wrapper is not required for ownership
  and is not copied into this project.
- **Zorin-specific mechanism:** the `com.rastersoft.ding` process identity,
  `Desktop Icons ` role, per-monitor state, override policy, and restart
  coordination.
- **Unsupported approach:** impersonating Zorin's client, patching its extension,
  compositor patches, repeated restacking, or actor-order loops.

An independent GNOME 46 extension can request and identify its own managed client
through the physically verified Mutter API. Ownership alone has not proved the
required relative layer: the three completed physical experiments show that
ordinary Meta.Window ordering, actor ordering, and window-list classification
are not authoritative for the required visual relationship.

### Architecture options after the failed experiments

1. **Companion extension plus existing Qt/WebEngine client:** preserves the
   preferred content process and is small, but needs a real desktop-layer API;
   managed-client ownership alone is insufficient evidence.
2. **Shell-owned visual actor fed by external content:** provides Shell layer
   control, but GNOME Shell has no demonstrated safe embedding path for an
   interactive Qt Wayland surface. Streaming pixels/input would add fragility
   and must not execute arbitrary network content inside Shell.
3. **Explicit cooperation with Zorin Desktop Icons:** the most credible next
   investigation. A reviewed provider hook could order an independently owned
   GrayHaired surface relative to the actual icon surfaces while leaving icon
   management with Zorin. Availability and maintenance support are unproven.
4. **Replacement desktop-icons provider:** could own the entire order but would
   violate the small-integration goal and create an unacceptable icon-manager
   maintenance burden.
5. **Normal-window Desktop Launch Page fallback:** safe and maintainable, but it
   is not the requested Desktop Mode layering.

### Zorin cooperation collector result

The read-only cooperation collector ran on the physical installed extension and
found no evidence that Zorin presents its visible icons in a Shell-owned actor or
container. The visible desktop remains external GTK client windows managed as
`Meta.Window` objects; `DesktopGrid` uses GTK widgets including `Gtk.EventBox`
and `Gtk.Fixed` inside those windows.

The extension exports session action-group/D-Bus behavior for functions such as
clipboard copy/cut, `disableTimer`, and `desktopGeometry`. No interface was found
for third-party surface registration, relative stacking, adoption of a foreign
Wayland client, extension-to-extension layer coordination, or insertion below
the icon windows. No stable non-title registration mechanism was found either.

The collector questions therefore have evidence-based answers:

1. **Shell-owned icon actor/container:** none found; visible icons are external
   GTK client-window content.
2. **Explicit layer/container coordination:** no usable point found.
3. **Exported cooperation API:** D-Bus/action-group behavior exists, but no
   surface-registration or relative-stacking interface was found.
4. **Stable registration below icon surfaces:** none found.

Accordingly, **no existing supported third-party cooperation point was found in
the installed Zorin Desktop Icons implementation**. This does not prove that
future cooperation is impossible, but patching or monkey-patching Zorin,
impersonating its trusted protocol, replacing it, or modifying its system files
is outside the project boundary. Option A is therefore unsupported by the
currently installed implementation and is not pursued further.

### Option B: Shell-owned external-content visual layer

The remaining architectural question is whether Shell can own an interactive
visual actor above wallpaper but below client windows while QtWebEngine remains
in the external Python process. Candidate APIs divide as follows:

- **Documented actor primitives:** Clutter/St actors expose child hierarchy,
  visibility, clipping, and reactive/input properties. Those primitives can draw
  and receive events, but do not document a stable GNOME desktop-layer contract.
- **Shell-private placement:** `Main.layoutManager._backgroundGroup` is private
  by naming and implementation. `Main.uiGroup`, `global.window_group`,
  `global.top_window_group`, stage ordering, and LayoutManager chrome methods are
  Shell/Mutter integration internals rather than a supported third-party surface
  protocol. Their presence does not make cross-version placement safe.
- **Unverified runtime relationship:** the observation-only hierarchy diagnostic
  logs group types, parents, sibling indexes, stage order, insertion/removal API
  availability, reactive state, and chrome helpers on the actual GNOME 46 target.
  It creates or reorders no actor.

Physical hierarchy collection on the Inspiron-3147 established:

```text
global.window_group (MetaWindowGroup)
└── backgroundGroup (MetaBackgroundGroup), sibling index 0
```

`global.window_group` is itself child index 0 of the Shell UI actor, while
`global.top_window_group` is child index 24. The window group exposes
`add_child`, `insert_child_at_index`, and `remove_child`. This makes one
GNOME-46-specific placement experiment structurally possible: insert a new
Shell-owned, non-window actor at the runtime-computed
`backgroundIndex + 1`. Unlike the failed experiments, this does not reorder a
`MetaWindowActorWayland`; it creates and later destroys only an actor owned by
the development extension.

`SHELL_OWNED_LAYER_EXPERIMENT = true` enables that single visual test. Managed
client auto-launch is disabled so its normal window cannot obscure the result.
After validating the background parent, insertion API, primary-monitor geometry,
and current background index, the extension creates a non-reactive `St.BoxLayout`
covering 42% by 24% of the primary monitor and labels it **GrayHaired Shell Layer
Test**. It inserts the actor immediately after the background group and logs the
before/after hierarchy. It never moves an existing child. Disablement destroys
only the retained test-actor reference.

This is a physical placement test, not an external-content prototype. Success
requires visual confirmation that the rectangle is above wallpaper, below
visible/clickable Zorin icons and normal windows, below panel/dock, stable, and
removed cleanly. The result cannot make private placement a supported API, nor
does it solve the external frame/input bridge described below.

External content delivery has no small supported bridge:

| Mechanism | Feasibility and cost on GNOME 46 |
| --- | --- |
| Shared-memory images/local IPC | Technically buildable, but requires repeated full-frame copies, a custom protocol, damage tracking, authentication, and separate input forwarding. |
| Periodic screenshots/frame export | Simple conceptually but high CPU/memory bandwidth and latency at desktop size; unsuitable as a blind high-frame-rate design on the Inspiron-3147. |
| DMA-BUF | Potentially efficient, but QtWebEngine export, synchronization, lifetime, and GJS/Cogl import do not form a demonstrated supported extension API. |
| PipeWire/screencast portal | Designed for consent-mediated capture, not persistent zero-copy embedding into Shell; consumption and input forwarding would still require substantial privileged code. |
| RemoteDesktop/input portal | Consent and security semantics make it unsuitable as a transparent persistent input-forwarding foundation; accessibility and keyboard focus remain difficult. |
| D-Bus state plus local Shell rendering | Suitable for limited launcher state, not for preserving a live interactive Desktop Website. |

Architecture B1 (visual mirror plus forwarded input) is therefore large,
latency-sensitive, security-sensitive, difficult for accessibility/multi-monitor
support, and likely too costly on low-power hardware without a proven zero-copy
path. B2 (a Shell-local launcher) does not meet the live Desktop Website
requirement. No B3 mask/underlay mechanism distinct from the three failed
stacking operations has been identified.

The current decision remains **B: actor placement is plausible enough for one
small GNOME-46 physical test, but it is Shell-private; external interactive
content still requires an unproven, high-maintenance frame/input bridge**. Even a
successful rectangle test would not make the complete architecture suitable for
Version 1.0. Unless supported APIs or provider cooperation emerge, retain the
normal-window fallback and reconsider the full interactive Desktop Mode
requirement.

No option yet proves Version 1.0 Desktop Mode. Managed ownership is proven, but
the three isolated mutation approaches are closed as insufficient. Investigation
is now narrowed to the Shell-owned visual background question while keeping all
WebEngine/network execution in the Python process. A future provider-supported
cooperation API could change the Option A assessment, but none exists in the
installed implementation. No streaming, IPC, or cooperation implementation is
included in this phase.

## Required behavior matrix

Source inspection identified the concrete client-window mechanism. The prototype
must now be manually tested for:

- native Wayland first, plus X11 compatibility;
- application-first and extension-first startup;
- application and icon-provider close/restart/remap;
- extension enable/disable without restarting the application;
- overview enter/exit and Show Desktop;
- workspace creation/switching and sticky behavior;
- focus, keyboard, pointer, drag-and-drop, and accessibility;
- lock/unlock, login/logout, and Shell failure recovery;
- Zorin taskbar, panel, menu, tiling, and app-indicator behavior; and
- multiple monitors, hot-plug, scaling, rotation, work areas, and primary-monitor
  changes.

Success means the live Desktop Website and GrayHaired shortcuts remain
interactive, real Zorin icons remain above them, ordinary windows remain above
the desktop layer, Shell chrome remains above everything, and no focus is stolen.

## Security and installation boundary

GNOME Shell extensions execute with desktop-shell authority. Any future code must
be minimal, reviewed, GNOME-46-specific, and fail closed to normal/windowed mode.
It must keep untrusted Desktop Website content out of the Shell process, validate
any per-user IPC, and avoid secrets or page content in logs.

Installation must remain an explicit, manual per-user action. Normal application
startup must not write extension directories, enable extensions, restart Shell,
or change Zorin Desktop Icons. Nothing may require root, compositor patches,
disabled Wayland protections, or modifications to Zorin system files.

## X11 and Wayland conclusion at this stage

The X11 Qt trials remain valid: the Qt desktop-type window was hidden beneath
GNOME's desktop surface, while a visible stays-below normal window obscured the
real icons. The pure-Qt candidate therefore remains only a fallback for
non-GNOME X11 environments.

For GNOME Shell 46 on Zorin, both X11 and Wayland may benefit from one integration
if the installed provider exposes a usable managed-client cooperation point.
Native-Wayland physical evidence now establishes the identities, runtime API
exposure, discovery path, actor hierarchy, managed ownership, and three failed
desktop-layer approaches.
Wayland security must remain intact.

The revised conclusion is: **`Meta.Window.lower()`, direct
`MetaWindowActorWayland` sibling reordering, and managed-client
`hide_from_window_list()` are all physically insufficient on the tested
Zorin/GNOME Shell 46 Wayland target**. The current mode is
`SAFE_INVESTIGATION_ONLY = true`; no live stacking or window-list mutation is
active. Managed ownership is physically proven, but desktop-layer semantics and
required relative stacking are not. No supported cooperation point was found in
the installed Zorin provider, and the Shell-owned mirror alternative currently
depends on private placement plus a costly, unproven frame/input bridge. Desktop
Mode remains unresolved at version `0.9.0`, and Version 1.0 is not complete.
