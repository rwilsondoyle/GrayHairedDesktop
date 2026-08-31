# Live Desktop Development and Reload Safety

## Purpose

This document defines the safe development workflow for the GrayHaired live desktop prototype on Zorin/GNOME. It is specifically intended to avoid repeated whole-extension teardown/re-enable cycles while editing DING/WebKit application code.

## Architecture summary

The Wayland prototype uses a separate user extension UUID:

`grayhaired-live-desktop@grayhaired.tech`

The implementation follows DING's normal two-process architecture:

- GNOME Shell extension process: owns integration with GNOME Shell, geometry/Wayland cooperation, and child-process supervision.
- Separate GTK/GJS DING child: runs `app/ding.js`, owns desktop icons, the GTK desktop window, and the embedded WebKit view.

Most GrayHaired live-desktop work is inside the child `app/` tree. Restarting that child is sufficient to load changes to files such as:

- `app/ding.js`
- `app/desktopGrid.js`
- `app/desktopManager.js`
- other child-side DING/GTK/WebKit modules

A whole GNOME extension disable/enable is unnecessary for those changes.

## Why repeated whole-extension toggling is discouraged

On the Inspiron/Zorin test system, GNOME Shell session-mode extension teardown has independently produced failures in Zorin Taskbar/AppIndicator/Menu code. Lock/unlock reproduced the failure even with GrayHaired completely disabled, so GrayHaired is not the root cause of that Zorin issue.

However, repeatedly hot-toggling the GrayHaired GNOME extension needlessly exercises the same GNOME/Zorin teardown path. Development should therefore avoid it unless extension-side code itself truly changed.

## Safe reload levels

### Level 1 — Website/HTML/JavaScript only

Use the embedded WebKit page's right-click Reload command. No process restart is required.

### Level 2 — DING/WebKit child code under `app/`

Use:

```bash
bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
```

The script:

1. Verifies `grayhaired-live-desktop@grayhaired.tech` is already ACTIVE.
2. Finds the exact GrayHaired `app/ding.js` child process.
3. Sends SIGTERM only to that child.
4. Waits for the old PID to exit.
5. Relies on the already-active DING extension's normal child supervision to relaunch the desktop program.
6. Waits for exactly one replacement PID.
7. Verifies the replacement process remains alive.
8. Never calls `gnome-extensions disable` or `gnome-extensions enable`.
9. Never touches Zorin Taskbar, AppIndicators, Menu, Tiling Shell, or unrelated extensions.

If the extension is not ACTIVE, the reload script stops with an error rather than trying to repair the GNOME session automatically.

### Level 3 — GNOME extension-side code (`extension.js`, Wayland integration)

Prefer a normal logout/login so GNOME Shell starts a fresh extension module in a fresh session.

Do not assume a disable/enable toggle reloads changed `extension.js` reliably: GJS module caching and session-mode interactions make logout/login the cleaner development boundary on this environment.

## WebKit lifecycle notes

The WebKit view is a GTK child of the DING desktop window. Signal connections added by GrayHaired use DING's existing `SignalManager` path, and `DesktopGrid.destroy()` disconnects registered signals before destroying the top-level window. Destroying the GTK window destroys its child widget hierarchy, including the WebKit view.

The lifecycle logging patch adds concise create/destroy markers and clears the GrayHaired `_liveWebView` / `_liveLayout` references after window destruction. It does not manually double-destroy WebKit children.

New asynchronous handlers should always either:

- be connected through the existing signal manager, or
- have an explicit cancellation/disconnect path before the desktop window is destroyed.

The external-link policy handler is synchronous and does not leave a pending promise/timer behind.

## Keyboard/input ownership

DING connects key events at the top-level desktop window. Because WebKit is inside that same window, WebKit key events can bubble to DING. The GrayHaired keyboard-focus guard checks whether `_liveWebView` owns focus before invoking DING's `onKeyPress()` or `onKeyRelease()` handlers.

Known-good behavior:

- WebKit focused: typing belongs to webpage text fields and does not trigger DING type-to-search.
- Mouse-driven DING icon behavior remains supported: left click, right-click menu, drag/drop, and saved positions.

Intentional current limitation:

- Do not force focus onto the DING `Gtk.EventBox` with `set_can_focus(true)` / `grab_focus()`.
- That experiment made Escape partially work, did not restore arrow-key navigation, and repeated focus switching immediately preceded a hard machine lockup.
- Escape/arrow-key DING desktop navigation is therefore not part of the current Wayland acceptance baseline.

Do not remove the WebKit guard, globally disable DING keyboard handling, or reintroduce forced EventBox focus without a separately proven safer design.

## Installer behavior

`scripts/install-wayland-separate-ding-prototype.sh` creates the separate user-local extension from the installed Zorin DING extension and applies the complete known-good split-surface patches, including:

- 220-pixel DING icon strip geometry
- WebKit live surface
- external-link handoff to the default browser
- safe WebKit keyboard-focus guard
- concise WebKit lifecycle logging

The installer is for installation/reinstallation, not routine code reloads.

## Read-only known-good verification

Use:

```bash
bash ~/GrayHairedDesktop/scripts/verify-wayland-known-good.sh
```

This verifier does not edit files, stop processes, reload WebKit, or toggle extensions. It checks that:

- the separate user-local extension exists
- WebKit2 integration and the 220-pixel split are present
- external-link handoff is present
- the safe WebKit keyboard guard is present
- lifecycle logging is present
- the experimental EventBox `grab_focus()` / forced-focus code is absent
- the current session is Wayland
- the GrayHaired extension is ACTIVE
- exactly one GrayHaired DING/WebKit child is running
- the normal system Zorin DING child is not simultaneously running

For an installed tree that is not currently active, the file-only checks can be run with:

```bash
bash ~/GrayHairedDesktop/scripts/verify-wayland-known-good.sh --files-only
```

## Logging

The reload script logs concise lifecycle markers with the prefix:

`[GRAYHAIRED-RELOAD]`

WebKit creation, destruction, and external navigation use:

`[GRAYHAIRED-WEBKIT]`

These logs are intentionally low-volume. Do not add per-frame, per-motion, or per-keystroke journal logging in normal builds.

## Development rule

For normal live-desktop development, stop using this pattern:

```bash
gnome-extensions disable grayhaired-live-desktop@grayhaired.tech
sleep 2
gnome-extensions enable grayhaired-live-desktop@grayhaired.tech
```

Use WebKit page Reload for website changes, child-only reload for `app/` changes, and logout/login only for genuine GNOME extension-side changes.
