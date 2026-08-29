# Live Desktop Research Notes

## Goal

Make **My Desktop** behave like the desktop background itself rather than like a normal bordered application window. The existing My Desktop page must remain visually/functionally intact, including its weather, search boxes, red menu buttons, category columns, Folders links, dropdown/menu behavior, and external links. Real Zorin desktop icons must still be available when desired.

## Safety rules

- Do not directly modify Zorin's installed extension under `/usr/share/gnome-shell/extensions/...` during research.
- Use reversible user-local prototypes.
- Preserve cleanup/recovery commands.
- A logout/login is acceptable when GNOME Shell must reload. Avoid kernel reboot unless genuinely required.
- Keep known-good X11 and Wayland prototypes intact before trying new approaches.
- For routine child-side DING/WebKit development, do not hot-toggle the GNOME extension. Use `scripts/reload-grayhaired.sh` as documented in `docs/live-desktop-development.md`.
- Do not force keyboard focus onto the DING icon-strip `Gtk.EventBox` on mouse click. That experiment did not restore arrow-key navigation and was followed by a full machine lockup during repeated focus switching. Preserve the safer WebKit keyboard guard instead.

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
5. The working arrangement keeps DING's EventBox/Fixed hierarchy in a dedicated left strip and places WebKit beside it.
6. WebKitGTK needs explicit navigation/new-window policy handling so page links are handed to the default browser.
7. DING listens for keyboard events at the shared top-level desktop window. When WebKit owns focus, those bubbled events must not also be sent to DING type-to-search. The GrayHaired keyboard guard preserves WebKit text entry.
8. Forcing the DING `Gtk.EventBox` to reclaim keyboard focus with `set_can_focus(true)` and `grab_focus()` on icon click was tested and rolled back. Escape began working, arrow-key navigation still did not, and repeated focus testing was followed by a full system lockup. Do not reintroduce that focus-reclaim method without a separately proven safer design.

## Current verified Wayland milestone

Original test system: Dell Inspiron 3147, Zorin/GNOME Wayland.

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
- disabling and re-enabling the GrayHaired Wayland extension restores the page, icon strip, saved icon positions, webpage links/Folders, and icon click/right-click/drag behavior: PASS (historical test only; no longer the preferred development reload method)
- normal logout/login on Wayland restores My Desktop automatically, restores the real desktop icons in their saved positions, restores the Zorin taskbar, and preserves links/Folders behavior without manual intervention: PASS
- normal reboot restores My Desktop, desktop icons and saved positions, Zorin taskbar, webpage links/Folders, and icon click/right-click/drag behavior: PASS
- WebKit text input no longer triggers DING's `Clear Current Selection before New Search` popup; both tested page text fields accept typing normally: PASS
- after rolling back forced DING focus reclaim, four regression checks passed: WebKit text boxes work, no DING search-warning popup appears, icon left-click/right-click/drag work, and links/Folders work: PASS
- `verify-wayland-known-good.sh` passes all file and runtime checks, including exactly one GrayHaired DING/WebKit child and no system Zorin DING child: PASS
- `check-wayland-zorin-base.sh` passes all structural compatibility checks against the installed system Zorin Desktop Icons extension: PASS
- `check-wayland-recovery.sh` passes all recovery prerequisites in read-only mode: current Wayland session, untouched system Zorin tree, GrayHaired installed and ACTIVE, exactly one GrayHaired DING/WebKit child, no system Zorin DING child, and no changes made: PASS
- after centralizing the known-good Wayland defaults into `scripts/wayland-layout-defaults.sh`, the full runtime verifier still passes: shared defaults valid, My Desktop URL unchanged, all WebKit/DING guards present, exactly one GrayHaired child running, and no system Zorin DING child: PASS

### Inspiron 3502 fresh-install checkpoint — PASS

A second physical Wayland test machine is now available and has successfully installed the same research branch:

- hardware: Dell Inspiron 3502
- OS: Zorin OS 18.1
- GNOME Shell: 46.0
- session: Wayland
- kernel at install: `7.0.0-30-generic`
- graphics: Intel UHD Graphics 600 / Gemini Lake using `i915`
- RAM: 16 GB DDR4
- display: 1366x768
- BIOS: 1.24.0 dated 2025-06-06

Fresh installation on the 3502 passed the full known-good verifier:

- GrayHaired extension Enabled: Yes / State: ACTIVE
- system Zorin Desktop Icons Enabled: No
- exactly one GrayHaired `ding.js` child running
- no system Zorin DING child running
- WebKit integration, keyboard guard, lifecycle logging, link handoff, and shared defaults all PASS

This makes the 3502 the preferred primary development/test machine, while the 3147 remains a useful older-hardware compatibility machine.

### Adaptive icon-strip checkpoint on Inspiron 3502 — PASS

The fixed `220`-pixel strip has now been replaced experimentally on the 3502 with a startup-time adaptive width derived from DING's own grid geometry.

DING source values on this Zorin 18.1 build:

- `elementSpacing = 2`
- desired cell widths from `Prefs.get_desired_width()`: tiny 70, small 90, standard 120, large 130
- DING column formula: `desired width + 4 * elementSpacing`

GrayHaired adaptive defaults currently use:

- two DING columns
- 8 pixels of strip padding
- minimum width 160
- maximum width 320
- fallback width 220 if geometry cannot be determined safely

With the active Zorin desktop icon setting `tiny`, the runtime log reported:

`[GRAYHAIRED-LAYOUT] icon cell=78px columns=2 strip=164px`

Physical result on the 1366x768 Inspiron 3502:

- left icon strip visibly reduced from the old 220px width: PASS
- icons/labels remain usable and visually proportionate: PASS
- My Desktop receives the reclaimed horizontal space: PASS
- GrayHaired extension remains ACTIVE: PASS
- exactly one GrayHaired DING/WebKit child is running: PASS
- system Zorin DING child is absent: PASS
- WebKit integration, adaptive geometry marker, keyboard guard, lifecycle logging, external-link handoff, and forbidden focus-reclaim checks all PASS in `verify-wayland-known-good.sh`

The verifier was updated to understand both the adaptive layout and the previous fixed-width layout during the transition. A one-time rollback copy of the pre-adaptive `desktopGrid.js` was saved as `desktopGrid.js.pre-adaptive` on the 3502.

Current conclusion: adaptive strip sizing is a successful Wayland direction and should become the permanent installer behavior after additional physical checks with at least one larger DING icon-size setting.

Known intentional keyboard limitation at this milestone:

- forced DING keyboard-focus reclaim is disabled
- Escape/arrow-key desktop navigation is not considered part of the current Wayland acceptance baseline
- mouse-driven icon behavior remains the supported path for the left DING strip

### Tested Zorin Desktop Icons compatibility baseline

The system Zorin Desktop Icons extension used for the known-good Wayland milestone reported:

- name: `Zorin Desktop Icons`
- metadata version: not present / reported as `unknown`
- supported shell versions in metadata: `46`, `47`, `48`, `49`, `50`
- extension UUID: `zorin-desktop-icons@zorinos.com`
- system `desktopGrid.js`: no GrayHaired markers present
- all installer structural anchors used by `install-wayland-separate-ding-prototype.sh`: PASS

The preflight script `scripts/check-wayland-zorin-base.sh` should be run before any future install/reinstall. If a Zorin update changes one of the required DING structures, installation should stop rather than patching an unverified base.

Observed metadata after moving icons during the Wayland test included:

- `my-desktop-gmail.desktop`: `112,2`
- `my-desktop-news.desktop`: `112,410`

This confirms DING is persisting moved icon positions, not merely leaving them visually in place for the current session.

Relevant research-branch commits leading to the milestone include:

- `a42c599` — add separate UUID Wayland DING installer
- `4d172a1` — add separate UUID Wayland DING cleanup
- `4239c82` — constrain DING grid width in Wayland split surface
- `fad35ee` — preserve grid margin without starving WebKit
- `61ec8e3` — add Wayland WebKit external link handoff
- `2984250` — add child-only GrayHaired development reload script
- `6dbbc17` — preserve WebKit keyboard focus from DING search
- `985c849` — experimental DING focus reclaim; later judged unsafe and rolled back
- `98f5b38` — remove forced DING focus reclaim after lockup evidence
- `5b11ae9` — add known-good runtime verifier and installer reproducibility gate
- `1b46812` — add Zorin/DING base compatibility preflight
- `8602345` — add two-stage recovery preflight and explicit `--apply` removal guard
- `07bf269` — centralize Wayland icon-strip width and My Desktop URL defaults
- `9aadafb` — add adaptive icon-strip experiment based on DING cell geometry
- `4fa78cf` — update verifier for adaptive layout defaults

## Inspiron Zorin lock/unlock issue — ENVIRONMENTAL, NOT CAUSED BY GRAYHAIRED

During Wayland testing, locking the screen caused GNOME Shell's extension session transition to fail, leaving enabled extensions such as Zorin Taskbar, Zorin Menu, and GrayHaired Live Desktop in `INACTIVE` state.

A controlled A/B test was performed with `grayhaired-live-desktop@grayhaired.tech` completely disabled before locking. The Zorin taskbar still disappeared after lock/unlock, proving that this failure occurs independently of GrayHairedDesktop.

The journal captured failures in Zorin's own AppIndicator/Taskbar path, including errors such as `TypeError: this._indicator is null`, followed by an unhandled promise rejection from GNOME Shell's `_sessionUpdated()` during lock/unlock session-mode transitions.

Treat this as a separate Inspiron/Zorin/GNOME environment issue. Do not change GrayHairedDesktop code merely to work around it without separate evidence.

Because whole-extension hot reload also exercises GNOME Shell's extension teardown path, routine GrayHaired app-code development now uses a child-only DING/WebKit restart instead. See `docs/live-desktop-development.md`.

## Development reload architecture

The GrayHaired GNOME extension owns and supervises a separate `app/ding.js` GTK/GJS child process. Most live-desktop changes are inside that child process, so the safe routine reload command is:

```bash
bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
```

The script sends SIGTERM only to the GrayHaired child and waits for the already-active extension to relaunch exactly one replacement child. It does not disable/re-enable GNOME extensions or touch Zorin Taskbar, AppIndicator, Menu, Tiling Shell, or unrelated extensions.

For website-only changes, use WebKit page Reload. For genuine `extension.js` changes, prefer a normal logout/login.

## Recovery architecture

Recovery/removal is deliberately two-stage. `scripts/check-wayland-recovery.sh` is read-only and verifies that the system Zorin extension is intact, GrayHaired is installed, the expected child-process state is present, and no conflicting system Zorin DING child is running. The actual remover does nothing unless explicitly invoked with:

```bash
bash ~/GrayHairedDesktop/scripts/remove-wayland-separate-ding-prototype.sh --apply
```

Do not run the apply step merely as a routine test on a working system. The read-only recovery preflight is the normal verification path.

## Wayland layout defaults

The Wayland layout settings are centralized in `scripts/wayland-layout-defaults.sh` so the adaptive patch and verifier use one source of truth rather than duplicating values.

Current adaptive defaults:

- DING icon columns: `2`
- strip padding: `8` pixels
- minimum strip width: `160` pixels
- maximum strip width: `320` pixels
- fallback strip width: `220` pixels
- My Desktop URL: `https://grayhaired.tech/desktop-d`

The adaptive runtime width is calculated from DING's own desired grid-cell width at child startup. Changing these defaults does not alter an already-running installation by itself.

## Open design questions / next work

The adaptive icon strip is now physically verified on the Inspiron 3502 with the `tiny` DING icon-size setting. The next useful validation is to test one or more larger DING icon-size settings and confirm the strip expands to the expected width while preserving icon click/right-click/drag behavior and My Desktop usability.

Do not move to page-aware icon-safe areas until the adaptive strip has been verified across more than one DING icon-size setting.

The current split-surface milestone is stable across WebKit page reload, child-process restart, normal Wayland logout/login, reboot, the post-focus-rollback regression test, known-good runtime verification, Zorin-base structural preflight, recovery preflight, centralized-default verification, a clean fresh installation on the Inspiron 3502, and the first adaptive-width physical test. Lock/unlock testing on the older Inspiron 3147 remains contaminated by the independent Zorin extension-session bug described above.

## Local `research/` directory

The original 3147 test machine has an untracked `research/` directory created from safe local copies of Zorin DING files used during earlier experiments. Do not assume it belongs in Git. Review its contents before committing anything from it.
