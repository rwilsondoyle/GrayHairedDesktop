#!/usr/bin/env python3
"""Temporary, reversible Live Desktop experiment for physical Zorin testing.

This intentionally does not enable a product feature. It copies the user's
current My Desktop settings into a temporary INI file, disables prototype
autostart, and shows the existing MainWindow as a frameless, stays-below
work-area-sized window. Closing the prototype removes the temporary settings.

Prototype-only keyboard experiments:
- Ctrl+Alt+D asks the Live Desktop window to recover after Show Desktop.
- Ctrl+Alt+Q exits the prototype.

The recovery shortcut is deliberately application-local. Physical testing must
show whether the desktop environment delivers it after Show Desktop has made
the prototype inactive; no global desktop shortcut is installed or modified.
"""

from __future__ import annotations

import logging
import sys
import tempfile
from pathlib import Path

from PySide6.QtCore import QSettings, Qt
from PySide6.QtGui import QKeySequence, QShortcut

from grayhaired_desktop.app import build_application
from grayhaired_desktop.config import AppMetadata, create_settings
from grayhaired_desktop.desktop_mode import detect_session
from grayhaired_desktop.logger import configure_logging
from grayhaired_desktop.ui.mainwindow import MainWindow


def copy_settings(source: QSettings, destination: QSettings) -> None:
    """Copy current user-facing settings into an isolated prototype store."""

    for key in source.allKeys():
        destination.setValue(key, source.value(key))
    # The prototype must never create, repair, or remove an autostart entry.
    destination.setValue("preferences/autostart", False)
    destination.setValue("preferences/desktopMode", False)
    destination.sync()


def main() -> int:
    metadata = AppMetadata()
    logger = configure_logging(logging.INFO).getChild("live-desktop-prototype")
    app = build_application(sys.argv)
    session = detect_session(app.platformName())

    with tempfile.TemporaryDirectory(prefix="grayhaired-live-desktop-") as directory:
        source_settings = create_settings(metadata)
        prototype_settings = QSettings(
            str(Path(directory) / "prototype.ini"), QSettings.Format.IniFormat
        )
        copy_settings(source_settings, prototype_settings)

        window = MainWindow(
            metadata,
            prototype_settings,
            logger,
            session,
            launch_executable=None,
        )

        flags = (
            Qt.WindowType.Window
            | Qt.WindowType.FramelessWindowHint
            | Qt.WindowType.WindowStaysOnBottomHint
        )
        window.setWindowFlags(flags)
        window.setMinimumSize(0, 0)
        window.statusBar().hide()

        screen = window.screen() or app.primaryScreen()
        if screen is None:
            logger.error("No screen is available for the Live Desktop prototype")
            return 2
        geometry = screen.availableGeometry()
        window.setGeometry(geometry)

        def recover_live_desktop() -> None:
            """Request a visible, active Live Desktop after Show Desktop."""

            logger.info(
                "Prototype recovery shortcut fired; visible=%s minimized=%s active=%s",
                window.isVisible(),
                window.isMinimized(),
                window.isActiveWindow(),
            )
            if window.isMinimized():
                window.showNormal()
            elif not window.isVisible():
                window.show()
            else:
                # Re-showing an already-visible window asks the compositor/window
                # manager to reconsider it after a Show Desktop transition.
                window.hide()
                window.show()
            window.setGeometry(geometry)
            window.raise_()
            window.activateWindow()

        recovery_shortcut = QShortcut(QKeySequence("Ctrl+Alt+D"), window)
        recovery_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        recovery_shortcut.activated.connect(recover_live_desktop)

        # A dedicated exit shortcut avoids relying on a title bar that the
        # prototype deliberately does not have.
        exit_shortcut = QShortcut(QKeySequence("Ctrl+Alt+Q"), window)
        exit_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        exit_shortcut.activated.connect(window.close)

        # Keep explicit Python references for the lifetime of the prototype.
        window._live_desktop_recovery_shortcut = recovery_shortcut
        window._live_desktop_exit_shortcut = exit_shortcut

        logger.info(
            "Prototype session=%s Qt=%s geometry=%dx%d%+d%+d",
            session.session_type,
            session.qt_platform,
            geometry.width(),
            geometry.height(),
            geometry.x(),
            geometry.y(),
        )
        logger.info("Prototype recovery shortcut: Ctrl+Alt+D")
        logger.info("Prototype exit shortcut: Ctrl+Alt+Q")

        window.show()
        window.lower()
        return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
