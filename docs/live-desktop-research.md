# Live Desktop Research Notes

## Goal

Make **My Desktop** behave like the desktop background itself rather than like a normal bordered application window. The existing My Desktop page must remain visually/functionally intact, including its weather, search boxes, red menu buttons, category columns, Folders links, dropdown/menu behavior, and external links. Real Zorin desktop icons must still be available when desired.

## Safety rules

- Do not directly modify Zorin's installed extension under `/usr/share/gnome-shell/extensions/...` during research.
- Use reversible user-local prototypes.
- Preserve cleanup/recovery commands.
- A logout/login is acceptable when GNOME Shell must reload. Avoid kernel reboot unless genuinely required.
- Keep known-good X11 and Wayland prototypes intact before trying new approaches.

## X11 findings

### Qt live desktop prototype

A Qt/PySide6 live My Desktop prototype successfully displays `https://grayhaired.tech/desktop-d` as a desktop-like live surface and hands external links to the default browser.

### X11 transparent icon-zone experiment — PASS

A Qt window mask/cutout can expose the untouched Zorin/DING desktop below it on X11.

A 220-pixel left-side icon zone was tested successfully:

- real Zorin/DING icons visible: PASS
- icon left click: PASS
- icon right-click menu: PASS
- icon drag within exposed zone: PASS
- moved position persists after closing prototype: PASS
- My Desktop links outside icon zone: PASS

A small per-icon hole was insufficient for dragging because a drag can leave the hole and cross back into the live My Desktop window. A continuous icon-safe zone works.

## Wayland findings

### Qt window-mask approach — FAIL

The X11 Qt mask/cutout technique does not expose DING underneath on GNOME Wayland. My Desktop remains clickable, but the intended DING strip is not visible/clickable.

### Standalone GTK3 ordinary window test — NOT SUITABLE

A normal GTK3/GJS window did not become a true full-screen desktop surface under GNOME Wayland. GNOME controlled its placement/size, so this was not a valid route for the final desktop layer.

### GTK Layer Shell

`GtkLayerShell` is not installed on the test system. More importantly, GNOME Wayland is not the target compositor for the layer-shell approach, so this avenue was not pursued.

### DING D-Bus inspection

DING exposes a standard `org.gtk.Actions` action group at `/com/rastersoft/dingextension/control`.

Observed actions:

- `doCut`
- `disableTimer`
- `desktopGeometry`
- `doCopy`

`desktopGeometry` reported the monitor geometry and margins (1366x768 on the test Inspiron, bottom margin 54). It does not expose icon rectangles, stacking controls, or selective click-through regions, so it is not sufficient for the live-desktop integration by itself.

### Same-UUID user-local Zorin extension override — FAIL

A user-local copy using the original Zorin UUID was ignored by GNOME session mode. GNOME continued loading the system extension from `/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com`.

### Separate-UUID Wayland DING/WebKit extension — PASS

A separate user-local extension was created with UUID:

`grayhaired-live-desktop@grayhaired.tech`

The normal Zorin Desktop Icons extension can be disabled cleanly during the test, and the separate prototype can run its own copied DING process without modifying the system extension.

Important implementation findings:

1. DING's top-level window width and icon-grid width are separate concerns.
2. `updateWindowGeometry()` keeps the top-level desktop window full monitor width.
3. The usable DING grid width can be constrained by `marginRight`.
4. The large right margin must **not** also be applied as a GTK widget margin inside the horizontal split, or it consumes WebKit's allocation.
5. The working arrangement keeps DING's EventBox/Fixed hierarchy in a 220-pixel left strip and places WebKit beside it.
6. WebKitGTK needs explicit navigation/new-window policy handling so page links are handed to the default browser.

## Current verified Wayland milestone

Test system: Dell Inspiron 3147, Zorin/GNOME Wayland.

Extension state at the milestone:

- `grayhaired-live-desktop@grayhaired.tech`: Enabled, ACTIVE, user-local path under `~/.local/share/gnome-shell/extensions/`
- `zorin-desktop-icons@zorinos.com`: disabled for this test; system files untouched

Verified behavior:

- real DING icon strip visible on left: PASS
- My Desktop visible at normal usable width on the remainder: PASS
- DING icon left click: PASS
- DING icon right-click context menu: PASS
- DING icon drag within strip: PASS
- dragged position stays: PASS
- dragged position is written to desktop metadata: PASS
- My Desktop normal links: PASS
- My Desktop Folders links: PASS
- My Desktop webpage receives right-click/input: PASS
- WebKit page reload preserves page, icon strip, saved icon positions, links, and Folders behavior: PASS
- disabling and re-enabling the GrayHaired Wayland extension restores the page, icon strip, saved icon positions, webpage links/Folders, and icon click/right-click/drag behavior: PASS
- normal logout/login on Wayland restores My Desktop automatically, restores the real desktop icons in their saved positions, restores the Zorin taskbar, and preserves links/Folders behavior without manual intervention: PASS

Observed metadata after moving icons during the Wayland test included:

- `my-desktop-gmail.desktop`: `112,2`
- `my-desktop-news.desktop`: `112,410`

This confirms DING is persisting moved icon positions, not merely leaving them visually in place for the current session.

Relevant research-branch commits leading to the milestone:

- `a42c599` — add separate UUID Wayland DING installer
- `4d172a1` — add separate UUID Wayland DING cleanup
- `4239c82` — constrain DING grid width in Wayland split surface
- `fad35ee` — preserve grid margin without starving WebKit
- `61ec8e3` — add Wayland WebKit external link handoff

## Inspiron Zorin lock/unlock issue — ENVIRONMENTAL, NOT CAUSED BY GRAYHAIRED

During Wayland testing, locking the screen caused GNOME Shell's extension session transition to fail, leaving enabled extensions such as Zorin Taskbar, Zorin Menu, and GrayHaired Live Desktop in `INACTIVE` state.

A controlled A/B test was performed with `grayhaired-live-desktop@grayhaired.tech` completely disabled before locking. The Zorin taskbar still disappeared after lock/unlock, proving that this failure occurs independently of GrayHairedDesktop.

The journal captured failures in Zorin's own AppIndicator/Taskbar path, including errors such as `TypeError: this._indicator is null`, followed by an unhandled promise rejection from GNOME Shell's `_sessionUpdated()` during lock/unlock session-mode transitions.

Treat this as a separate Inspiron/Zorin/GNOME environment issue. Do not change GrayHairedDesktop code merely to work around it without separate evidence.

## Open design questions / next work

The 220-pixel left icon strip is a proven coexistence mechanism, but it is not necessarily the final UX. A future design may use page-aware icon-safe areas. The user's idea is that regions with live/clickable My Desktop content remain controlled by My Desktop, while noninteractive regions could be available to real desktop icons. Any such design must account for dynamic dropdowns/menus that can temporarily occupy otherwise empty space.

The current split-surface milestone is stable across WebKit page reload, controlled extension disable/enable, and normal Wayland logout/login. Lock/unlock testing on this Inspiron is still contaminated by the independent Zorin extension-session bug described above.

## Local `research/` directory

The test machine currently has an untracked `research/` directory created from safe local copies of Zorin DING files used during earlier experiments. Do not assume it belongs in Git. Review its contents before committing anything from it.
