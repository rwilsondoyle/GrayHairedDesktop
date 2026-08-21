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

Use the embedded WebKit page's Reload command. No process restart is required.

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

The GrayHaired code should not manually double-destroy WebKit children. New asynchronous handlers should always either:

- be connected through the existing signal manager, or
- have an explicit cancellation/disconnect path before the desktop window is destroyed.

The external-link policy handler is synchronous and does not leave a pending promise/timer behind.

## Keyboard/input ownership

DING connects key events at the top-level desktop window. Because WebKit is inside that same window, WebKit key events can bubble to DING. The GrayHaired keyboard-focus guard therefore checks whether `_liveWebView` owns focus before invoking DING's `onKeyPress()` or `onKeyRelease()` handlers.

This preserves both behaviors:

- WebKit focused: typing belongs to webpage text fields.
- DING/icon area focused: DING keyboard navigation/type-to-search remains available.

Do not remove this guard or replace it by globally disabling DING keyboard handling.

## Installer behavior

`scripts/install-wayland-separate-ding-prototype.sh` creates the separate user-local extension from the installed Zorin DING extension and now applies the complete known-good split-surface patches, including:

- 220-pixel DING icon strip geometry
- WebKit live surface
- external-link handoff to the default browser
- WebKit keyboard-focus guard

The installer is for installation/reinstallation, not routine code reloads.

## Logging

The reload script logs concise lifecycle markers with the prefix:

`[GRAYHAIRED-RELOAD]`

WebKit external navigation uses:

`[GRAYHAIRED-WEBKIT]`

These logs are intentionally low-volume. Do not add per-frame, per-motion, or per-keystroke journal logging in normal builds.

## Development rule

For normal live-desktop development, stop using this pattern:

```bash
gnome-extensions disable grayhaired-live-desktop@grayhaired.tech
sleep 2
gnome-extensions enable grayhaired-live-desktop@grayhaired.tech
```

Use child-only reload for `app/` changes and logout/login only for genuine GNOME extension-side changes.
