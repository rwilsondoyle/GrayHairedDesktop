# GrayHairedDesktop Codex Notes

This repository includes a live-desktop research effort for Zorin OS / GNOME.

## Before changing live-desktop code

1. Read `docs/live-desktop-research.md` and `docs/live-desktop-development.md` first.
2. Preserve known-good X11 and Wayland prototypes before experimenting.
3. Do not edit files under `/usr/share/gnome-shell/extensions/...` during research.
4. Prefer user-local, reversible prototypes and include cleanup/recovery instructions.
5. Do not require a kernel reboot unless it is genuinely necessary. Session logout/login is acceptable when GNOME Shell must reload extension code.
6. Keep the user's existing My Desktop page behavior intact. Do not simplify or remove links, menus, folders, dropdowns, search boxes, weather, or other page behavior just to make desktop integration easier.
7. Treat real Zorin/DING desktop icons as a requirement: left click, right-click context menu, drag/drop, and saved positions must continue to work.
8. **Do not use repeated `gnome-extensions disable/enable grayhaired-live-desktop@grayhaired.tech` cycles as the normal development reload mechanism.** For files under the copied DING `app/` tree, use `scripts/reload-grayhaired.sh`, which restarts only the GrayHaired DING/WebKit child process.
9. If `extension.js` itself changes, prefer a normal logout/login over hot-toggling the extension. The Inspiron test environment has an independent Zorin/GNOME session-mode bug in which extension teardown can strand Zorin Taskbar/AppIndicator/Menu inactive.
10. HTML/site-only changes should use WebKit page Reload; they do not require a DING or GNOME extension restart.

## Current working Wayland milestone

The research branch `codex/research-live-desktop-mode` has a working Wayland split-surface prototype using a separate user extension UUID:

`grayhaired-live-desktop@grayhaired.tech`

At the milestone recorded in `docs/live-desktop-research.md`, the separate prototype is active, the normal system Zorin Desktop Icons extension is disabled for testing, DING occupies a 220-pixel left icon strip, and the live My Desktop WebKit surface occupies the remainder of the desktop. DING icon click/right-click/drag work, My Desktop links and Folders work, icon positions persist, page reload works, controlled child restart works, logout/login works, and WebKit text fields keep keyboard focus instead of triggering DING type-to-search.

Do not regress this milestone while experimenting.
