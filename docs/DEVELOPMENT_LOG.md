# Development Log

This log records project-level development milestones and verification notes. It is intentionally concise so future contributors can quickly understand what changed and what still needs confirmation.

## GNOME Shell Desktop Integration Feasibility

Status: Managed ownership verified; four desktop-layer mechanisms physically rejected.

- Confirmed the target as Zorin OS 18.1 and GNOME Shell 46.0; Phase 1 completed
  successfully in the intended native Wayland session.
- Confirmed `zorin-desktop-icons@zorinos.com` (**Zorin Desktop Icons**) as the
  active provider. Its metadata names the original Desktop Icons extension, while
  installed headers confirm substantial DING-derived implementation code.
- Targeted inspection established that a separate application renders the icons
  in client windows. Zorin manages their `Meta.Window` objects event-by-event,
  including Wayland desktop semantics, lowering, workspace behavior, Activities
  filtering, and per-monitor positioning.
- Retained the proven conclusion that pure Qt window hints cannot preserve the
  required layer. Physical Wayland tests also proved that one `lower()` call and
  direct compositor-actor sibling ordering are insufficient.
- Confirmed `list_all_windows()`, stack sorting, and `window-created` at runtime;
  recorded both client identities and their starting stack. Lowering only
  GrayHaired did not change the order; verification failed and fallback worked.
- Confirmed both Wayland window actors share one `MetaWindowGroup`; changing
  their reported sibling order did not change the visible icon relationship, and
  the experiment restored the previous order.
- Installed-source inspection identified Mutter's
  `Meta.WaylandClient.new_subprocess(global.context, launcher, argv)` as Zorin's
  trusted-client primitive. Added an independently written ownership-only test
  that directly launches the configured Python interpreter, validates managed
  ownership plus exact GrayHaired WM identity, performs no stacking operation,
  and never relaunches automatically.
- The first physical ownership test found `new_subprocess` undefined on GNOME
  Shell 46 and failed safely without launching. The prototype now tests only the
  installed-source-demonstrated older forms—`new(global.context, launcher)` or
  `new(launcher)` followed by managed `spawnv(global.display, argv)`—with no
  ordinary subprocess fallback.
- A subsequent GNOME 46 run exposed `new`, `spawnv`, and window-list methods but
  no raw `query_window_belongs_to`; the managed process was terminated safely.
  Installed source shows Zorin's wrapper implements that method by calling raw
  `Meta.WaylandClient.owns_window(window)`. The ownership test now uses
  `owns_window()` directly and matches Zorin's constructor order:
  `new(launcher)` first, then `new(global.context, launcher)` on failure.
- Physical testing on the Inspiron-3147 proved the context constructor, managed
  `spawnv`, exact GrayHaired WM identity, and `owns_window(window) === true`.
  Manual window close was detected normally and caused no automatic relaunch.
- The one-shot managed `hide_from_window_list(window)` test changed only
  `skipTaskbar` (false to true). Type and layer remained 0 and 2, stack order
  remained wrong, and real Zorin icons stayed underneath GrayHaired. Ordinary
  windows and panel/dock stayed above. The mutation code is removed.
- `Meta.Window.lower()`, actor sibling reorder, and managed window-list hiding
  are now physically rejected as Desktop Mode solutions. No combinations or
  retry loops are justified. Next work is read-only investigation of an explicit
  Zorin cooperation point or a Shell-owned visual layer with WebEngine outside
  Shell.
- The physical read-only cooperation collector found external GTK icon windows,
  no Shell-owned icon container, and no D-Bus/API surface-registration or
  relative-layer hook. Option A is unsupported by the installed implementation.
- Option B currently requires Shell-private actor placement plus an unproven
  external frame/input bridge. Full-frame mirroring is especially unsuitable for
  low-power hardware without a supported zero-copy path. No implementation was
  added; the normal-window fallback remains and product requirements need review.
- Physical hierarchy diagnostics found `backgroundGroup` at child index 0 inside
  `global.window_group` and confirmed child insertion/removal APIs. One controlled
  test temporarily enabled a non-reactive extension-owned `St.BoxLayout` at the
  runtime-computed background index plus one. Managed-client auto-launch was off,
  and no existing actor or window was moved. The test is now disabled by default.
- The physical Shell-owned actor test failed: the rectangle was above wallpaper
  but also above Zorin icons and normal applications; panel/dock remained above.
  Icons were clickable underneath and no obvious flicker occurred, but recovery
  required explicit terminal disable and the enabled extension recreated the
  actor after reboot. This exact insertion is rejected and both experiment flags
  now default false.
- Added a stable Qt Wayland application ID and X11 `WM_CLASS` without changing
  QSettings identity. Nothing is installed or enabled automatically. Version
  remains 0.9.0, and Desktop Mode remains a pre-1.0 investigation item.

## Alpha 0.8 — Stability, Performance and Diagnostics

Status: Implementation complete; manual verification performed on the Inspiron-3147 test system.

- Added a persistent rotating log alongside existing terminal output at `~/.local/state/GrayHairedDesktop/grayhaired-desktop.log`.
- Timed `QApplication` creation, main-window creation, and main-window display from a shared startup timestamp.
- Added numbered Desktop Website measurements that distinguish initial startup, Home, Reload, and Settings-triggered loads.
- Timed only the `QDesktopServices.openUrl()` handoff for clicked links and desktop shortcuts; this is not a measurement of the external browser's page load.
- Added **Help → Open Log Folder** and documented combined terminal capture for Python, Qt, Chromium, Mesa, and graphics-stack output.
- Added diagnostics to investigate startup and loading performance. No performance improvement or graphics configuration change is claimed.

### Inspiron-3147 Zorin diagnostic run

Manual testing verified persistent log creation, **Help → Open Log Folder**, a successful initial Desktop Website load, a successful Settings-triggered load, Home, Reload, and external shortcut handoff.

| Measurement | Observed time |
| --- | ---: |
| QApplication created | 0.331 seconds |
| Main window created | 1.644 seconds |
| Main window shown | 1.725 seconds |
| Initial Desktop Website load | 3.072 seconds |
| Settings-triggered load | 2.282 seconds |
| Home load | 0.554 seconds |
| Reload | 0.495 seconds |

These measurements are from one diagnostic run on the Inspiron-3147 test system. They are not universal performance benchmarks and do not establish that performance has improved.

## Alpha 0.7 — Customizable Desktop Shortcuts

Status: Implementation complete; manual verification pending.

- Implemented a compact launcher below the Desktop Website with no visible Favorites heading.
- Implemented **+ Add Shortcut**, hover help, and a right-click menu for **Edit Shortcut** and confirmation-protected **Remove Shortcut**, with friendly validation and a built-in symbol chooser.
- Preserved shortcut order in `QSettings`, allowed multiple shortcuts of the same type, and retained an intentionally empty list.
- Routed shortcut clicks through the existing external-opening mechanism so the Desktop Website remains unchanged.

## Milestone history

### Initial foundation

- Created the repository and early Python project files.
- Added the application entry point and requirements needed for a PySide6 desktop shell.

### Alpha 0.1

- Added the initial package skeleton under `src/grayhaired_desktop`.
- Established the QtWebEngine direction for rendering a configurable web experience inside a native desktop window.

### Alpha 0.2

- Implemented the first functional browser shell.
- Added a native `QMainWindow` hosting an embedded browser view.
- Confirmed the application could launch through the Python entry point.

### Alpha 0.3

- Added user-facing navigation for Home and Reload.
- Added Preferences for editing the Home Page address.
- Added persistent preferences and persistent window geometry through `QSettings`.
- Added application, browser, preferences, load-success, and load-failure logging.

### Alpha 0.3.1 documentation foundation

- Added dedicated documentation for architecture, roadmap, changelog, development history, and project principles.
- Updated the README to direct users and contributors to the new documentation set.
- Completed manual verification on two physical Zorin systems.
- No application source code was changed for this documentation milestone.

### Task 009 UI refactor

- Separated action creation, menu construction, and toolbar construction into focused UI modules.
- Kept the main window responsible for browser coordination, preferences, status updates, dialogs, and persistent window state.
- Preserved the existing user-visible wording, layout, and behavior; this milestone adds no visible features.

### Alpha 0.4 desktop launch page

- Changed the embedded mini-browser into a desktop launch page.
- Kept the configured home page displayed inside the application while ordinary links open in the operating system's default browser.
- Covered ordinary clicks, `target="_blank"`, `window.open()`, and new-tab/new-window requests while preserving same-page fragment links.
- Removed Back and Forward actions, shortcuts, toolbar/menu entries, and browser-history coordination.
- Preserved Home, Reload, Preferences, About, Exit, window persistence, logging, and status-message behavior.
- The public product name is still undecided.
- Completed manual verification on both supported physical Zorin systems: Primary Development System and Secondary Test System.
- On both systems, successfully verified Application startup, Home page, Home, Reload, Preferences, About, Exit, external link launching, and that the Home page remains displayed after launching links.
- Alpha 0.4 is complete.

### Alpha 0.5 — Launch Page Personalization

Status: Implementation complete; manual Zorin verification pending.

- Improved Preferences with plain-English help and readable spacing.
- Added **Preview Home Page in Browser** to preview the entered address in the default browser without saving or closing Preferences.
- Added a confirmation-protected **Restore Default Home Page** action that only changes the field until **OK** is selected.
- Added reusable validation for complete HTTP and HTTPS addresses, with a friendly correction message.
- Preserved **Cancel** so edited and restored values do not replace the saved Home Page.
- Preserved the launch page, external links, Home, Reload, About, Exit, window state, status messages, and logging.
- No widget system has been added yet.


### Alpha 0.6 — Desktop Website Selection

Status: Implementation complete; manual Zorin verification pending.

- Replaced user-visible **Preferences** wording with **Settings**.
- Added **Another Website...** first and a separated, alphabetical built-in list: Bing, DuckDuckGo, Google, MSN, and Yahoo.
- Populated built-in choices from one reusable immutable display-name/address configuration structure.
- Enabled **Website Address** only for **Another Website...** and retained custom values when appropriate.
- Made **Preview in Browser** non-saving and non-destructive to the embedded page.
- Made **Save** validate custom choices and immediately apply them; **Cancel** preserves the previous selection and page.
- Preserved Alpha 0.5 navigation, external-link, persistence, status, logging, and script behavior.
- No widget system has been added.

## Zorin verification notes

### Version 0.9.0 single-instance guard (PR #43)

Status: Implementation, automated verification, and physical verification complete.

- Added a focused Qt local-IPC guard using `QLocalServer` and `QLocalSocket`, so
  no new dependency, launcher, service, or process-discovery mechanism is needed.
- A secondary launch sends one activation message and exits successfully before
  the WebEngine UI is imported. The primary restores a minimized window, shows a
  hidden window, and requests normal Qt raise/activation behavior.
- Stale endpoints are removed only after an initial connection failure, a failed
  listen, and a second connection failure consistent with refusal/not-found.
  Cleanup is restricted to the guard that successfully owns the endpoint.
- **X11 physical verification: PASSED.** On the Dell Inspiron-3147 under Zorin
  OS / GNOME / X11, the PR #43 build was installed through the existing
  `update-user-install.sh` path. The installed launcher and canonical XDG
  autostart worked, login produced exactly one instance, and a second
  `~/.local/bin/grayhaired-desktop` invocation returned normally without a
  second window. `pgrep -af 'venv/bin/grayhaired-desktop$'` confirmed a count of
  one real application process. GNOME displayed its visual attention/flashing
  indication rather than always forcing the existing window to the foreground;
  this is acceptable and requires no X11-specific focus hack.
- **Wayland physical verification: PASSED.** After logging into Zorin OS / GNOME
  / Wayland on the same Dell, canonical autostart again produced exactly one
  instance. A second installed-launcher invocation returned normally, created
  no second window, and left the process count at one. GNOME briefly displayed
  an already-open attention notice. This acceptable compositor behavior does
  not weaken the single-instance guarantee and requires no focus workaround.
- Desktop Website links showed no current performance problem during this
  physical follow-up.

## PR #43 recovery checkpoint (historical)

- PR #43 single-instance guard: implementation complete.
- Physical X11 verification: **PASSED**.
- Physical Wayland verification: **PASSED**.
- The stable installed launcher and canonical autostart from PR #42 remain
  working.
- Desktop Website links showed no current performance problem during physical
  follow-up.
- Version remains `0.9.0`.
- Desktop Mode remains unresolved and is still the principal Version 1.0
  blocker.
- Do not repeat the failed GNOME Shell layering experiments documented in PR
  #39.
- Next development work should begin from this checkpoint.

### GNOME Shell 46 desktop-layer feasibility

- Native-Wayland testing confirmed that `Meta.Window.lower()` did not change the
  relevant visible order and safely fell back.
- A second physical test changed the reported `MetaWindowGroup` sibling order,
  but GrayHaired Desktop still obscured Zorin's real desktop icons; restoration
  succeeded.
- Managed ownership is physically proven. Managed window-list classification
  then failed visually and its mutation was removed. Next work is read-only
  architecture inspection; Zorin Desktop Icons and ordinary windows remain
  untouched.
- Desktop Mode remains unresolved and Version 1.0 is not declared ready.

The project targets Zorin OS, so manual verification on real Zorin computers is part of the alpha process.

| Physical Zorin system | Status | Verified workflow and behavior |
| --- | --- | --- |
| Primary Development System | Successful | `git pull`; `scripts/setup-zorin.sh`; `scripts/update.sh`; `scripts/run.sh`; Application startup; Home page; Home; Reload; Preferences; About; Exit; external link launching; Home page remaining displayed after launching links. |
| Secondary Test System | Successful | `git pull`; `scripts/setup-zorin.sh`; `scripts/update.sh`; `scripts/run.sh`; Application startup; Home page; Home; Reload; Preferences; About; Exit; external link launching; Home page remaining displayed after launching links. |

These results record manual verification on exactly two physical Zorin systems. They do not represent automated GUI testing, completed Windows testing, or completed virtual-machine testing.

## Contributor workflow notes

- Keep source changes and documentation-only changes separated when practical.
- Do not alter application source code for documentation-only tasks.
- Prefer small milestones with clear manual verification steps.
- Record Zorin-specific findings in this log so future setup scripts and docs can improve from real installation feedback.

### PR #44 recovery checkpoint (historical)

- PR #44 release-readiness reconciliation is complete.
- PR #42 stable installation and canonical autostart remain physically verified
  on X11 and Wayland.
- PR #43 single-instance behavior remains physically verified on X11 and Wayland.
  GNOME attention indications instead of forced focus are acceptable.
- Desktop Website links have no currently observed performance issue.
- Version remains `0.9.0`; Version 1.0 is not declared ready.
- Desktop Mode on Zorin/GNOME remains the principal unresolved Version 1.0
  product requirement.
- PR #39 rejected Qt desktop-type and stays-below windows,
  `Meta.Window.lower()`, actor sibling ordering, managed window-list hiding, and
  the tested Shell-owned actor placement above `backgroundGroup`. Managed
  Wayland ownership passed but did not solve relative layering.
- Do not repeat those rejected mechanisms without materially new evidence.
- The next development task depends on an explicit Desktop Mode product decision:
  either retain Desktop Mode as a 1.0 requirement and investigate a materially
  new architecture, or explicitly revise Version 1.0 scope in a future
  owner-approved PR.
- PR #44 makes no such product-scope decision automatically.

### PR #45 recovery checkpoint (historical)

- PR #45 classification: **Result 3 — NO PRACTICAL SUPPORTED PATH FOUND**.
  Version 1.0 is not ready under the owner-selected PR #44 Path A.
- New architectures examined: live runtime cooperation with the Zorin extension;
  a shared Zorin icon-client GTK surface; a Shell shared container; Shell visual
  mirroring; PipeWire/GStreamer, DMA-BUF, Wayland-buffer, and shared-memory frame
  transport; a complete external input bridge; `wlr-layer-shell`; and supported
  GNOME/Mutter background or external-surface APIs.
- Runtime cooperation is technically reachable only through private Shell/Zorin
  implementation objects. The installed provider exposes no supported
  extension-to-extension contract, surface registry, or relative-layer callback,
  so this is not safe enough to ship.
- A shared visual surface is not available. Real icon pixels live in external
  per-monitor GTK client windows. Their transparency is alpha in the icon
  client's own buffer, not a foreign-content insertion facility. Sharing would
  require a new Zorin-supported provider API, modifying/replacing the icon
  client, or unsafe injection.
- An external QtWebEngine frame/input bridge is theoretically buildable as a
  remote-display subsystem, but is not practical for Version 1.0. No supported
  end-to-end zero-copy QtWebEngine-to-GJS/Clutter path was found, and pointer,
  keyboard/IME, focus, scrolling/hover, clipboard, external launch, accessibility,
  scaling, lifecycle, and authentication remain a large custom subsystem. The
  copy/readback risk is especially poor for the Dell Inspiron-3147.
- No upstream-supported GNOME Shell 46/Mutter mechanism supplies the required
  external-client/background layer. `wlr-layer-shell` is not supported by Mutter
  on the target; portal capture/control does not provide embedding.
- PR #45 physical read-only collector: **PASSED** on the Dell Inspiron-3147 in a
  Wayland session with GNOME Shell 46.0. Public Shell Extensions D-Bus state
  confirmed `zorin-desktop-icons@zorinos.com` enabled and active with no error,
  and process observation physically confirmed the external
  `app/ding.js` DING-derived icon client.
- Installed Zorin source physically confirmed that related Zorin extensions use
  `Main.extensionManager.lookup(...)`. Cross-extension lookup is technically
  present on this build, but no supported foreign-surface, relative-layer,
  shared-rendering, or GrayHaired background-content contract was found. Result
  3 is unchanged.
- The collector made no Shell Eval call and changed no setting, extension,
  process, window, actor, or installed file. PR #45 added no mutation prototype.
- Exact PR #46 next step: open an explicit owner product-decision PR to revisit
  PR #44 Path B—ship the safe windowed launch-page application as Version 1.0 and
  move true Desktop Mode to future provider/upstream research. PR #45 does not
  silently make that decision. Do not start another physical architecture test
  unless GNOME or Zorin first supplies a genuinely new supported hook.
- Do not repeat PR #39's rejected Qt desktop-type/stays-below windows,
  `Meta.Window.lower()`, direct actor sibling ordering, managed window-list
  hiding, the tested Shell actor above `backgroundGroup`, polling/restacking,
  title impersonation, or system-extension modification. Managed Wayland client
  ownership passed but did not solve relative layering.
- Version remains `0.9.0`.

## Version 1.0 Product Scope Decision — PR #46

- The owner selected PR #44 **Path B**.
- The safe, normal windowed launch-page application is the supported Version 1.0
  scope. It is not described as Desktop Mode.
- True Desktop Mode moved to **Future Research** and is no longer a Version 1.0
  blocker. Its exact layering requirement and the PR #39/PR #45 engineering
  history remain preserved.
- PR #45 **Result 3 — NO PRACTICAL SUPPORTED PATH FOUND** remains the current
  conclusion for Zorin OS / GNOME Shell 46.
- No runtime behavior, installer behavior, dependencies, application defaults,
  or Desktop Mode code paths changed in this documentation-only decision.
- Version remains `0.9.0`; Version 1.0 has not been released.
- The final Version 1.0 release-readiness/manual verification pass is next.

### NEXT DEVELOPMENT CHECKPOINT

- PR #46 owner product decision complete.
- PR #44 Path B selected.
- Version 1.0 scope is the safe windowed launch-page application.
- True Desktop Mode moved to future research.
- PR #45 Result 3 remains the current GNOME/Zorin feasibility conclusion.
- Do not repeat PR #39 rejected mechanisms without materially new evidence.
- Stable install/autostart from PR #42 remains verified.
- Single-instance behavior from PR #43 remains verified.
- Version remains `0.9.0`.
- Next task is the final Version 1.0 release-readiness/manual verification pass.
- Final version bump to `1.0.0` must occur only after that pass succeeds.

## Final Version 1.0 Release Readiness Audit — NO-GO

This checkpoint records the chronological state before the My Desktop
implementation. It is an audit only and contains no runtime implementation.

- **Release decision: NO-GO.**
- Version remains `0.9.0`.
- The automated readiness audit result is **54 passed, 10 skipped**.
- Final Wayland physical verification is pending.
- Final X11 physical verification is pending.
- The existing Desktop Mode Settings control is misleading and is a release
  blocker.
- The final public product name was still pending at the time of the audit.
- No runtime changes are included.
- No naming changes are included.
- No Settings changes are included.
- No launcher or autostart changes are included.
- No tests are changed.
- The audit does not create the My Desktop implementation.

The NO-GO decision remains in force pending resolution of the misleading
control, the public-name decision, both final physical verification passes, and
a later explicit release decision.

## My Desktop public-name and Settings implementation

- The public/display product name is now **My Desktop**.
- The GrayHairedDesktop technical/internal compatibility identity is preserved,
  including package and launcher names, application IDs, QSettings scope, data
  and log paths, and the single-instance endpoint.
- The unsupported Desktop Mode checkbox and its behavior promise were removed
  from normal Settings without disturbing Desktop Website, shortcut appearance,
  autostart, Preview, Save, or Cancel controls.
- A legacy `preferences/desktopMode=true` value is ignored and saved as false.
  Normal startup always requests the supported safe windowed path.
- Version remains `0.9.0`.
- The automated suite result for this implementation is **55 passed, 10
  skipped** in the available container; the skips are display-library-dependent
  GUI collections.
- Focused physical verification on the Dell Inspiron-3147, Zorin OS 18.1, and
  GNOME Shell 46 passed in both Wayland and X11 sessions.
- Installation wording, window title, application-menu name and Accessories
  category, Settings control removal, and preservation of the saved Desktop
  Website and shortcuts passed physically.
- Canonical login autostart passed on Wayland and X11. Duplicate launches in
  both sessions logged `Existing application instance notified; exiting`,
  produced no second window, and left exactly **1** real process.
- A focused CPU investigation isolated sustained use to the configured Desktop
  Website content: idle QtWebEngine with `about:blank` was essentially 0% CPU,
  while a plain QtWebEngine test of the same website reproduced the load. This
  is a separate future website-performance concern, not a PR #52 blocker.
- `QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"` made CPU usage worse and must not
  be added. No runtime behavior changed in response to this investigation.

### NEXT DEVELOPMENT CHECKPOINT

- PR #52 public/display rename to **My Desktop**: implementation complete and
  physically passed.
- GrayHairedDesktop internal compatibility identity preserved.
- Unsupported Desktop Mode control removed from normal Settings.
- Legacy `desktopMode=true` cannot activate unsupported behavior.
- Normal startup always uses safe windowed mode.
- Version remains `0.9.0`.
- Automated result: **55 passed, 10 skipped**.
- Focused Wayland physical verification: **PASSED**.
- Focused X11 physical verification: **PASSED**.
- Autostart on Wayland and X11: **PASSED**.
- Single-instance behavior on Wayland and X11: **PASSED**, with a final real
  process count of **1** after duplicate launch in each session.
- Application-menu visible name **My Desktop**: **PASSED**.
- Existing settings preservation: **PASSED**.
- The Desktop Website CPU performance concern was isolated to website content
  and is not a PR #52 blocker.
- Final release-readiness physical pass remains pending.
- After PR #52 merges, resume the final Version 1.0 release-readiness physical
  checklist.
- A `1.0.0` bump remains prohibited until that final readiness pass becomes GO
  and a later release decision authorizes it.

## Final post-PR #52 Version 1.0 Release Readiness — GO

- PR #51 remains the historical **NO-GO** checkpoint for the state before the
  naming, Desktop Mode UI cleanup, and final physical verification work.
- PR #52 was merged to `main` as `94d1929`; it established **My Desktop** as the
  public name, removed the unsupported Desktop Mode control, prevented legacy
  `desktopMode=true` from activating that mode, and preserved the
  GrayHairedDesktop / `grayhaired-desktop` compatibility identity.
- A clean install from that current-main merge using
  `./scripts/update-user-install.sh` succeeded on the Dell Inspiron-3147 with
  Zorin OS 18.1 and GNOME Shell 46. Version remained `0.9.0`.
- Final X11/Xorg physical release-readiness verification: **PASS**.
- Final Wayland physical release-readiness verification: **PASS**.
- Autostart, one-real-process single-instance behavior, normal Settings,
  Desktop Website and shortcut use, external link handoff, and compatibility
  logging passed in the applicable final checks. X11 Save/Cancel persistence
  and **Help → Open Log Folder** also passed.
- Configured-website CPU activity remains a separate, non-blocking performance
  follow-up. Plain QtWebEngine with the same site reproduced it, while
  `about:blank` was essentially idle; `--disable-gpu` made it worse and must not
  be added.
- **Final Version 1.0 release-readiness decision: GO.**
- The project may proceed only to a separate, small, controlled `1.0.0`
  release/version-bump PR after this GO checkpoint is reviewed and merged.
- This documentation checkpoint does not change runtime behavior or the
  current `0.9.0` version.
