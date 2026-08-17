# Roadmap

The desktop application is moving toward a dependable, easy-to-install desktop companion for Zorin OS users. The roadmap favors small, verifiable milestones that improve trust, installation confidence, and daily usability without overcomplicating the native shell.

## Vision

The project vision is to provide a comfortable desktop entry point: a native window, predictable controls, simple setup, persistent preferences, and a clear path for future contributors to enhance the experience safely.

## Naming

My Desktop is the public/display product name. GrayHairedDesktop remains the
technical/internal compatibility identity for existing installations. GrayHaired
Tech and Ron Doyle remain appropriate project attribution.

## Alpha milestones

### Alpha 0.1 — Project skeleton

Status: complete.

- Established the Python package layout.
- Added initial project metadata and dependency definitions.
- Created the foundation for a QtWebEngine-based desktop app.

### Alpha 0.2 — Browser shell

Status: complete.

- Implemented the native Qt main window.
- Embedded the configured desktop web experience in `QWebEngineView`.
- Added basic application startup and browser loading behavior.

### Alpha 0.3 — Preferences, navigation, and persistence

Status: complete.

- Added Home and Reload navigation actions.
- Added a Preferences dialog with OK, Cancel, and Restore Defaults controls.
- Persisted the configurable home page URL with `QSettings`.
- Persisted window geometry and window state.
- Added structured logging around startup, shutdown, preferences, and page loading.

### Alpha 0.3.1 — Documentation and Zorin install confidence

Status: complete.

- Added the docs foundation in this directory.
- Kept the README focused on quick start and pointed contributors to deeper documentation.
- Documented current architecture, development history, project principles, and release notes.
- Completed manual setup and runtime verification on two physical Zorin systems: Primary Development System and Secondary Test System.
- On both systems, successfully verified `git pull`, `scripts/setup-zorin.sh`, `scripts/update.sh`, `scripts/run.sh`, Application startup, Home, Reload, Preferences, About, and Exit.

### Alpha 0.4 — Desktop launch page

Status: complete.

- Established the product direction as a desktop launch page rather than an embedded mini-browser.
- Kept the configured home page inside the application while clicked links open in the operating system's default browser.
- Supported ordinary links, `target="_blank"`, `window.open()`, and new-tab/new-window requests.
- Removed Back and Forward controls, shortcuts, and browser-history behavior.
- Preserved Home, Reload, Preferences, window persistence, status, About, and Exit behavior.
- Completed manual verification on both supported physical Zorin systems: Primary Development System and Secondary Test System.
- On both systems, successfully verified Application startup, Home page, Home, Reload, Preferences, About, Exit, external link launching, and that the Home page remains displayed after launching links.
- The public product name is still undecided.

### Alpha 0.5 — Launch Page Personalization

Status: Implementation complete; manual Zorin verification pending.

- Improved Preferences with plain-English help, clear controls, and readable spacing.
- Added non-saving **Preview Home Page in Browser** and confirmation-protected **Restore Default Home Page** actions.
- Added friendly validation for complete HTTP and HTTPS addresses.
- Ensured **Cancel** preserves the previously saved Home Page.
- Preserved all Alpha 0.4 launch-page behavior.
- Deliberately added no widget system, dashboards, themes, accounts, or cloud synchronization.

### Alpha 0.6 — Desktop Website Selection

Status: Implementation complete; manual Zorin verification pending.

- Replaced **Preferences** with clearer **Settings** wording.
- Put **Another Website...** first and placed an alphabetical built-in list after a separator.
- Enabled **Website Address** only for custom selections and sourced built-ins from one reusable configuration structure.
- Ensured **Preview in Browser** does not save, **Save** applies the selection, and **Cancel** preserves the previous selection.
- Added no widget system.

### Alpha 0.7 — Customizable Desktop Shortcuts

Status: Implementation complete; manual verification pending.

- Added a compact, naturally wrapping shortcut launcher below the dominant Desktop Website, without a visible Favorites heading.
- Added **+ Add Shortcut**, concise hover help, and a right-click menu for **Edit Shortcut** and confirmation-protected **Remove Shortcut**, without permanent edit buttons.
- Allowed multiple shortcuts of the same type and persisted the complete ordered list with `QSettings`.
- Opened every shortcut externally while leaving the Desktop Website unchanged.

### Alpha 0.8 — Stability, Performance and Diagnostics

Status: Implementation complete; manual verification performed on the Inspiron-3147 test system.

- Added persistent rotating logs while retaining terminal output.
- Added startup timing and numbered Desktop Website load timing for initial, Home, Reload, and Settings-triggered loads.
- Added external-link handoff timing that measures only the operating-system handoff call.
- Added diagnostics intended to investigate startup and loading performance; no performance improvement is claimed yet.
- Left GPU, Vulkan, VA-API, hardware-acceleration, and GPU-rendering settings unchanged.
- Verified the diagnostic workflow in one machine-specific Zorin run; the observed timings are not universal performance benchmarks.

## Near-term priorities after Alpha 0.8

- Add lightweight Markdown/documentation checks to the development workflow.
- Consider smoke-test coverage for importability and non-GUI helpers.
- Improve contributor setup notes as real Zorin installation feedback accumulates.
- Keep native desktop features focused on shell responsibilities: launching, preferences, diagnostics, and platform integration.

### Alpha 0.9 — Usability and Accessibility Review

Status: Implementation complete; final manual Zorin verification pending.

- Began the review with a focused pass on accessible control metadata and consistent top-menu behavior.
- Added a toggleable control menu so the Desktop Website gets more screen space while the existing application controls remain easy to reach.
- Implemented the click-target and spacing review for shortcuts, menus, and settings dialogs while preserving the compact desktop layout.
- Implemented a focused wording and terminology review across menus, dialogs, help text, accessibility descriptions, and user-facing messages.
- Confirmed consistent use of **Settings**, **Desktop Website**, **Website Address**, **Shortcut**, and **Open controls** in the current user interface.
- Implemented the keyboard-navigation review, including complete dialog focus sequences and reliable focus return to the Desktop Website when native controls close.
- Implemented the high-contrast and large-system-text compatibility review by removing fixed native-UI font sizes and retaining system fonts, palettes, focus behavior, and high-DPI handling.
- Added a focused Zorin compatibility fallback for PySide6 installations where the Fusion palette does not reflect GNOME's current light/dark appearance.

- Completed the final senior-friendly usability pass, clarifying that Shortcut
  Appearance affects shortcut buttons only and aligning explicit Light and Dark
  button outlines without increasing the shortcut area.
- Next: complete the separate Version 1.0 release-readiness review and final
  manual Zorin verification. Version 1.0 is not yet declared complete.

## Version 1.0 release readiness

Status: **Version 1.0.0 released.** The owner selected PR #44 Path B in PR
#46, and PR #53 completed the final release-readiness **GO** checkpoint. The
supported Version 1.0 product is the safe, normal windowed launch-page
application; it is not presented as Desktop Mode.

- PR #42 completed the stable user-local installation, application-menu launch,
  update/uninstall lifecycle, and single canonical XDG autostart entry. X11 and
  Wayland login/autostart checks passed on the physical Dell Inspiron-3147.
- PR #43 completed the Qt local-IPC single-instance guard. X11 and Wayland
  physical checks passed: a second invocation returned normally, created no
  second window, and left one real process. GNOME attention indications are an
  acceptable focus-policy result, not a blocker.
- PR #51's historical audit was **NO-GO**. PR #52 then established **My
  Desktop**, removed unsupported Desktop Mode from normal Settings, preserved
  compatibility identifiers, and passed focused X11 and Wayland checks.
- The post-PR #52 clean-main install at `94d1929` passed the final physical
  checklist on the Dell Inspiron-3147 in both X11/Xorg and Wayland. The final
  Version 1.0 release-readiness decision is **GO**.
- Configured Desktop Website CPU use is a separate non-blocking optimization
  follow-up; controlled testing reproduced it in plain QtWebEngine loading the
  same site, not with idle `about:blank`. Do not add `--disable-gpu`.
- Version `1.0.0` was released after the PR #53 GO checkpoint. Post-1.0 work is
  maintenance and future-roadmap work, not release-blocker work. See
  [`RELEASE_READINESS.md`](RELEASE_READINESS.md) for the status table, exact
  Desktop Mode definition, and preserved rejected-approach record.

## Principal post-1.0 direction — Wallpaper Mode

Status: implementation complete; physical Wayland and X11 verification
**PASSED** on the Dell Inspiron-3147 with Zorin OS 18.1 / GNOME Shell 46.

- Render the configured Desktop Website as a static primary-screen PNG through
  normal GNOME/Zorin wallpaper configuration.
- Preserve separate light/dark wallpaper URIs and picture options, with manual
  Set, Refresh, and Restore actions.
- Keep real desktop icons owned and operated by Zorin. Do not change GNOME
  Shell, Mutter layering, normal window behavior, or autostart.
- Defer automatic refresh and mixed-DPI multi-monitor composition until after
  physical reliability, CPU, and visual-quality testing.
- Wallpaper Mode is a non-interactive picture; **True Desktop Mode** remains
  separate Future Research for a hypothetical live interactive layer.
- Physical testing confirmed the actual Zorin wallpaper, sizing/readability,
  real-icon visibility and usability, Refresh, Restore, and Wayland Light/Dark
  persistence. The next work may investigate safe desktop interactivity or
  future wallpaper enhancements without conflating them with True Desktop Mode.

## Future research — true Desktop Mode

True Desktop Mode retains its exact historical requirement—an interactive
GrayHaired Desktop surface between the GNOME wallpaper and the user's real Zorin
Desktop Icons—but is no longer a Version 1.0 blocker. PR #45's current result is
**Result 3 — NO PRACTICAL SUPPORTED PATH FOUND** on Zorin OS / GNOME Shell 46.

Research should resume only if at least one material premise changes: Zorin
Desktop Icons adds a supported background/provider API; GNOME/Mutter adds a
supported external-surface or background layer; Zorin supplies an explicit
third-party integration point; Mutter supports a relevant new upstream
protocol; or a substantially different architecture avoids the rejected
mechanisms. A routine GNOME or Zorin update alone is not a reason to repeat the
experiments. Preserve and consult PR #39 and PR #45 evidence before future work.

## Longer-term ideas

- Improve error handling and user-facing diagnostics when the configured web destination cannot load.
- Add desktop integration assets, such as an icon and `.desktop` launcher, when branding is ready.
- Explore release packaging only after the alpha setup scripts are consistently verified on target systems.
- Evaluate accessibility and high-DPI behavior on the target Zorin hardware.
- Build an equivalent Windows version only as future platform work; Windows and
  macOS are not supported by the current release.

## Post-1.0 Desktop Shortcuts milestone (PR #56)

- Standard user-level launchers derived from existing shortcuts: implemented.
- Preserve Zorin icons and manage only marked files: automated coverage complete; Inspiron verification pending.
- Wayland physical add/open/remove check: **PENDING**.
- X11 physical add/open/remove check: **PENDING**.
- Live interactive True Desktop Mode remains separate **Future Research**.
