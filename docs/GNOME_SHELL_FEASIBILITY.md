# GNOME Shell Desktop Integration Feasibility

## Current status

This investigation remains open. Real testing has proved that pure Qt window
hints do not provide the required GNOME desktop layer, but it has **not** proved
that cooperation with the installed Zorin desktop-icon extension is impossible.
A GNOME Shell prototype is included as manually installed development source.
The lower-only Phase 2 experiment failed safely. Actor diagnostics then confirmed
a shared compositor group, so the current mode is a single controlled actor-order
experiment. Normal application startup still installs or enables nothing. The
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
| Current inspected session | X11 |
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

The current physical result is from X11. Wayland is still the primary product
requirement, so the same version/provider facts and behavior must also be checked
after logging into a normal Zorin Wayland session. Users must not be required to
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
first native window. Qt's desktop-file name supplies the native Wayland
application ID, while `QT_WM_CLASS` supplies the X11 resource class. Existing
QSettings organization/application keys are unchanged, so this compositor
identity does not relocate user preferences.

The development extension requires an exact match from `get_wm_class()`,
`get_wm_class_instance()`, or `get_gtk_application_id()`; it never uses the title.
The precise property populated by PySide6 must be recorded in GNOME Looking Glass
on native Wayland and X11 before this identity is considered physically verified.

| Identifier | Role | Limitation |
| --- | --- | --- |
| Wayland application ID | Preferred primary native-Wayland identity | Must be explicitly configured and observed on the target. |
| X11 `WM_CLASS` | Preferred native-X11 identity | Does not define native Wayland identity. |
| `get_gtk_application_id()` | Useful when populated | PySide6 must not assume this GTK-oriented value exists. |
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

Phase 1 is complete and the lower-only Phase 2 result is recorded below. The
source now defaults to `ACTOR_DIAGNOSTIC_ONLY = true`; normal application startup
still does not install or enable the extension.

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

### Controlled actor-order experiment

`ACTOR_EXPERIMENT_MODE = true` enables the smallest actor-level test. It obtains
both actors from the production-matched Meta.Windows and requires one shared
parent. Before mutation it logs sanitized actor order and Meta.Window order
separately.

If GrayHaired's child index is already lower than every Zorin actor index, it logs
**Actor order already correct** and does nothing. Otherwise the only initial
mutation is:

```javascript
parent.set_child_below_sibling(grayActor, zorinActor);
```

It never invokes `Meta.Window.lower()`/`raise()`, never directly reorders the
Zorin actor, never uses `set_child_at_index()`, and makes no geometry, workspace,
focus, type, or window-list change.

Immediate verification requires a common parent, visible GrayHaired and Zorin
actors, GrayHaired below every icon actor in the parent's child array, and
unchanged relative ordering among ordinary application actors. Meta.Window order
is logged before and after but is deliberately not a pass condition.

Only one mutation is permitted per enablement. If a later meaningful event shows
that Mutter changed the order again, the extension logs the change but does not
repeat the mutation or fight the compositor.

Before a mutation, the extension remembers GrayHaired's previous and next
siblings. On failure or disable it restores GrayHaired above the surviving prior
previous sibling or below the surviving prior next sibling. If neither anchor is
safe, it makes no speculative change and logs logout/login as the development
fallback.

This remains a physical visual experiment, not a completed architecture. Mutter
may later reassert its authoritative window stack even if one actor-order test
works, so overview, focus, remap, monitor, and sustained behavior still require
observation.

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
if the installed provider exposes a usable actor group or window lifecycle. The
X11 session facts do not establish native-Wayland behavior, and Wayland security
must remain intact.

The revised conclusion is: **pure Qt and a single `Meta.Window.lower()` call are
both insufficient, while the confirmed shared actor parent makes one controlled
Clutter sibling-order test structurally valid**. Its visual and sustained result
is not yet known. Desktop Mode on Zorin/Wayland remains under investigation for
Version 1.0; Version 1.0 is not complete.
