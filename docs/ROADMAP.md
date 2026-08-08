# Roadmap

The desktop application is moving toward a dependable, easy-to-install desktop companion for Zorin OS users. The roadmap favors small, verifiable milestones that improve trust, installation confidence, and daily usability without overcomplicating the native shell.

## Vision

The project vision is to provide a comfortable desktop entry point: a native window, predictable controls, simple setup, persistent preferences, and a clear path for future contributors to enhance the experience safely.

## Naming

GrayHairedDesktop is the repository and package identity; GrayHaired Desktop is current working/display wording. The final public product name remains undecided before Version 1.0, and this release-readiness phase does not select one. GrayHaired Tech and Ron Doyle remain appropriate project attribution.

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

Status: **Version 1.0 implementation review complete; final manual Zorin
verification pending.** Version 1.0 is not declared complete.

- Audited current product/version wording, About information, installation,
  update/run paths, persistence, logging, safety, and dependencies.
- Documented the source-checkout distribution method, public-documentation gaps,
  release findings, and the required 50-item manual Zorin checklist in
  [`RELEASE_READINESS.md`](RELEASE_READINESS.md).
- Retained Version 1.0 as a release decision to be made only after review and
  successful manual testing.

## Longer-term ideas

- Improve error handling and user-facing diagnostics when the configured web destination cannot load.
- Add desktop integration assets, such as an icon and `.desktop` launcher, when branding is ready.
- Explore release packaging only after the alpha setup scripts are consistently verified on target systems.
- Evaluate accessibility and high-DPI behavior on the target Zorin hardware.
- Build an equivalent Windows version only as future platform work; Windows and
  macOS are not supported by the current release candidate.
