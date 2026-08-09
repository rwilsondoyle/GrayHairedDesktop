# GNOME Shell Desktop Integration Feasibility

## Current status

This investigation remains open. Real testing has proved that pure Qt window
hints do not provide the required GNOME desktop layer, but it has **not** proved
that cooperation with the installed Zorin desktop-icon extension is impossible.
No GNOME Shell extension prototype is included, installed, or enabled in this
phase. The project remains version `0.9.0`, and a safe Zorin/Wayland Desktop Mode
remains a pre-Version 1.0 investigation requirement.

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

## Question the source inspection must answer

The installed JavaScript must establish which model Zorin Desktop Icons uses:

### A. Shell-owned icon actors

Icons might be `Clutter`/`St` actors attached directly to a Shell-owned group. If
so, determine the parent group, per-monitor organization, whether the extension
uses `Main.layoutManager`, `addChrome()`, `global.window_group`, or sibling-order
methods, and what it does during overview, workspace, and monitor changes.

This model may expose a plausible actor insertion point between background and
icons. It is feasible only if that point is stable in GNOME 46, can preserve
input and accessibility, and does not depend on mutating Zorin's system files or
private state with no lifecycle contract.

### B. Separate compositor/client windows

The extension might launch a process that creates desktop windows and then track
them through `Meta.Window` or window-created signals. If so, determine its stable
window identity, window type, one-window-per-monitor behavior, workspace rules,
and exact stacking operations.

This model might allow a GNOME 46 extension to place the PySide6 window relative
to the icon windows through Mutter. It is not proven reliable until remapping,
focus, overview, Show Desktop, workspace, lock/unlock, and monitor changes are
tested on both Wayland and X11.

### C. A combination

The extension may use Shell actors for coordination and separate client windows
for icon rendering. In that case both halves and their enable/disable ordering
must be understood. An apparent actor group does not prove that icon pixels live
in it, and a process launcher does not prove that actor ordering is irrelevant.

Until the diagnostic output is reviewed, this report does not select A, B, or C
and does not claim that the required layer is either possible or impossible.

In particular, the next report must determine:

1. whether the visible icons are rendered in one or more GTK/client windows;
2. whether `extension.js` or `gnomeShellOverride.js` identifies those windows as
   `Meta.Window` objects;
3. whether it manipulates window actors or Mutter stacking;
4. which X11 behavior `emulateX11WindowType.js` emulates;
5. whether the provider assigns a special desktop-window role or classification;
6. how that classification and the icon windows behave under Wayland;
7. whether an existing lifecycle hook can place another recognized surface
   directly below every icon window; and
8. whether that hook is a practical GNOME 46 insertion point for the required
   wallpaper → GrayHaired Desktop → icons → applications → Shell chrome order.

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

A future experiment should set and verify an explicit reverse-DNS application or
desktop-file ID before its first window. On GNOME 46, inspect the corresponding
`Meta.Window` in Looking Glass and record all identifiers actually exposed by
native Wayland and X11.

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

## Candidate mechanisms after source inspection

### Relative compositor stacking

If Zorin Desktop Icons uses identifiable `Meta.Window` client surfaces and its
source already establishes a GNOME 46 stacking policy, a small extension may be
able to integrate GrayHaired Desktop into that policy. The desired operation is
not merely “lower the application”; it must keep the application immediately
below every icon surface and above the Shell background across every remap.

This is now a candidate, not a conclusion. It must not use a polling loop or
blindly call `lower()` because those approaches can flicker or fight Mutter. It
must follow the provider's actual lifecycle and fail back to a normal window.

### Shell actor insertion

If icon rendering is Shell-owned, a future prototype may create one actor per
monitor above the relevant background actor and below the provider's icon group.
The provider's source must reveal a stable insertion point or a safe cooperative
signal. Directly editing its actor tree through undocumented incidental fields
would carry significant GNOME/Zorin update risk.

A native Qt Wayland surface cannot simply be reparented into a Clutter actor.
Therefore an actor-only solution may still require a supported content-sharing
mechanism or a larger renderer change. Screenshot proxying is not accepted as an
interactive Desktop Website implementation.

### Provider cooperation

If neither public stacking nor a stable group is present, a narrowly reviewed
upstream change or documented API in Zorin Desktop Icons could be the smallest
reliable solution. This investigation may describe such cooperation, but this PR
must not patch `/usr/share`, replace the provider, or copy a modified system
extension.

## Required behavior matrix

A prototype is justified only after source inspection identifies a concrete
mechanism. It must then be manually tested for:

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

The honest conclusion is narrower than before: **pure Qt is insufficient, while
GNOME 46 cooperation with Zorin Desktop Icons is not yet determined**. Reviewing
the bounded diagnostic output is the next decision gate. Desktop Mode on
Zorin/Wayland remains under investigation for Version 1.0; Version 1.0 is not
complete or abandoned by this report.
