# Development Log

This log records project-level development milestones and verification notes. It is intentionally concise so future contributors can quickly understand what changed and what still needs confirmation.

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
- Added Preferences for editing the home page URL.
- Added persistent preferences and persistent window geometry through `QSettings`.
- Added application, browser, preferences, load-success, and load-failure logging.

### Alpha 0.3.1 documentation foundation

- Added dedicated documentation for architecture, roadmap, changelog, development history, and project principles.
- Updated the README to direct users and contributors to the new documentation set.
- No application source code was changed for this documentation milestone.

### Alpha 0.3.1 Verification Complete

- Alpha 0.3.1 is verified on both supported Zorin systems.

## Zorin verification notes

The project targets Zorin OS, so manual verification on real Zorin computers is part of the alpha process.

| System | Status | Verified workflows and controls |
| --- | --- | --- |
| Primary Development System | Verified | `git pull`, `scripts/setup-zorin.sh`, `scripts/update.sh`, `scripts/run.sh`, application startup, Home, Reload, Preferences, About, and Exit. |
| Secondary Test System | Verified | `git pull`, `scripts/setup-zorin.sh`, `scripts/update.sh`, `scripts/run.sh`, application startup, Home, Reload, Preferences, About, and Exit. |

Dual-system verification is complete for the two supported physical Zorin systems.

## Contributor workflow notes

- Keep source changes and documentation-only changes separated when practical.
- Do not alter application source code for documentation-only tasks.
- Prefer small milestones with clear manual verification steps.
- Record Zorin-specific findings in this log so future setup scripts and docs can improve from real installation feedback.
