# Roadmap

GrayHaired Desktop is moving toward a dependable, easy-to-install desktop companion for GrayHaired Tech users on Zorin OS. The roadmap favors small, verifiable alpha milestones that improve trust, installation confidence, and daily usability without overcomplicating the native shell.

## Vision

The project vision is to provide a comfortable desktop entry point for GrayHaired Tech: a native window, predictable controls, simple setup, persistent preferences, and a clear path for future contributors to enhance the experience safely.

## Milestones through Alpha 0.3.1

### Alpha 0.1 — Project skeleton

Status: complete.

- Established the Python package layout.
- Added initial project metadata and dependency definitions.
- Created the foundation for a QtWebEngine-based desktop app.

### Alpha 0.2 — Browser shell

Status: complete.

- Implemented the native Qt main window.
- Embedded the GrayHaired Tech desktop web experience in `QWebEngineView`.
- Added basic application startup and browser loading behavior.

### Alpha 0.3 — Preferences, navigation, and persistence

Status: complete.

- Added Home and Reload navigation actions.
- Added a Preferences dialog with OK, Cancel, and Restore Defaults controls.
- Persisted the configurable home page URL with `QSettings`.
- Persisted window geometry and window state.
- Added structured logging around startup, shutdown, preferences, and page loading.

### Alpha 0.3.1 — Documentation and Zorin install confidence

Status: in progress.

- Add the docs foundation in this directory.
- Keep the README focused on quick start and point contributors to deeper documentation.
- Document current architecture, development history, project principles, and release notes.
- Continue validating setup and runtime behavior on two Zorin computers. The first Zorin verification has been reported successful; the second verification should remain marked pending until it is completed and recorded in the development log.

## Near-term priorities after Alpha 0.3.1

- Add lightweight Markdown/documentation checks to the development workflow.
- Consider smoke-test coverage for importability and non-GUI helpers.
- Improve contributor setup notes as real Zorin installation feedback accumulates.
- Keep native desktop features focused on shell responsibilities: launching, navigation, preferences, diagnostics, and platform integration.

## Longer-term ideas

- Improve error handling and user-facing diagnostics when the hosted page cannot load.
- Add desktop integration assets, such as an icon and `.desktop` launcher, when branding is ready.
- Explore release packaging only after the alpha setup scripts are consistently verified on target systems.
- Evaluate accessibility and high-DPI behavior on the target Zorin hardware.
