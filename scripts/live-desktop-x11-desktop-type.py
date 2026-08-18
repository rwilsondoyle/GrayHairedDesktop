#!/usr/bin/env python3
"""X11-only Live Desktop prototype using the desktop window type.

This is a reversible physical experiment. It copies the user's current My Desktop
settings into a temporary INI file, disables autostart/Desktop Mode there, and
shows the existing MainWindow with Qt's X11 desktop-window attribute.
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
    for key in source.allKeys():
        destination.setValue(key, source.value(key))
    destination.setValue("preferences/autostart", False)
    destination.setValue("preferences/desktopMode", False)
    destination.sync()


def main() -> int:
    metadata = AppMetadata()
    logger = configure_logging(logging.INFO).getChild("live-desktop-x11-desktop-type")
    app = build_application(sys.argv)
    session = detect_session(app.platformName())

    if session.session_type not in {"x11", "xorg"} or session.qt_platform != "xcb":
        logger.error(
            "X11 desktop-type prototype requires X11/xcb; got session=%s Qt=%s",
            session.session_type,
            session.qt_platform,
        )
        return 2

    with tempfile.TemporaryDirectory(prefix="grayhaired-live-desktop-x11-") as directory:
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

        window.setAttribute(Qt.WidgetAttribute.WA_X11NetWmWindowTypeDesktop, True)
        window.setWindowFlags(Qt.WindowType.Window | Qt.WindowType.FramelessWindowHint)
        window.setMinimumSize(0, 0)
        window.statusBar().hide()

        screen = window.screen() or app.primaryScreen()
        if screen is None:
            logger.error("No screen is available for the X11 desktop-type prototype")
            return 2
        geometry = screen.availableGeometry()
        window.setGeometry(geometry)

        exit_shortcut = QShortcut(QKeySequence("Ctrl+Alt+Q"), window)
        exit_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        exit_shortcut.activated.connect(window.close)
        window._live_desktop_exit_shortcut = exit_shortcut

        logger.info(
            "X11 desktop-type prototype geometry=%dx%d%+d%+d",
            geometry.width(),
            geometry.height(),
            geometry.x(),
            geometry.y(),
        )
        logger.info("Prototype exit shortcut: Ctrl+Alt+Q")

        window.show()
        return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
