#!/usr/bin/env python3
"""Temporary X11 Live Desktop experiment with one real-desktop icon hole.

This prototype keeps the existing frameless, stays-below Live Desktop window but
removes one rectangle from the top-level Qt window mask.  On X11, pixels and
pointer input outside the mask belong to windows underneath, allowing a real
Zorin/DING desktop icon to show through and receive input without modifying the
DING extension.

The hole is intentionally hard-coded around the physically measured Gmail icon
for the first Inspiron experiment.  This is research only, not product code.
"""

from __future__ import annotations

import logging
import sys
import tempfile
from pathlib import Path

from PySide6.QtCore import QSettings, QRect, Qt
from PySide6.QtGui import QKeySequence, QRegion, QShortcut

from grayhaired_desktop.app import build_application
from grayhaired_desktop.config import AppMetadata, create_settings
from grayhaired_desktop.desktop_mode import detect_session
from grayhaired_desktop.logger import configure_logging
from grayhaired_desktop.ui.mainwindow import MainWindow

# Gmail metadata::nautilus-icon-position measured physically on the Inspiron.
GMAIL_X = 1183
GMAIL_Y = 104
# Give DING's icon, label, selection highlight, and context-menu hit area room.
HOLE_PADDING_X = 18
HOLE_PADDING_Y = 18
HOLE_WIDTH = 126
HOLE_HEIGHT = 126


def copy_settings(source: QSettings, destination: QSettings) -> None:
    """Copy current settings into an isolated prototype store."""

    for key in source.allKeys():
        destination.setValue(key, source.value(key))
    destination.setValue("preferences/autostart", False)
    destination.setValue("preferences/desktopMode", False)
    destination.sync()


def main() -> int:
    metadata = AppMetadata()
    logger = configure_logging(logging.INFO).getChild("live-desktop-x11-icon-hole")
    app = build_application(sys.argv)
    session = detect_session(app.platformName())

    if session.session_type not in {"x11", "xorg"} or session.qt_platform != "xcb":
        logger.error(
            "Icon-hole prototype requires native X11/xcb; session=%s Qt=%s",
            session.session_type,
            session.qt_platform,
        )
        return 2

    with tempfile.TemporaryDirectory(prefix="grayhaired-live-desktop-hole-") as directory:
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
            logger.error("No screen is available for the icon-hole prototype")
            return 2

        geometry = screen.availableGeometry()
        window.setGeometry(geometry)

        # Convert the root-desktop Gmail position into this window's coordinates.
        hole_x = GMAIL_X - geometry.x() - HOLE_PADDING_X
        hole_y = GMAIL_Y - geometry.y() - HOLE_PADDING_Y
        hole = QRect(hole_x, hole_y, HOLE_WIDTH, HOLE_HEIGHT)

        full_region = QRegion(window.rect())
        visible_region = full_region.subtracted(QRegion(hole))
        window.setMask(visible_region)

        exit_shortcut = QShortcut(QKeySequence("Ctrl+Alt+Q"), window)
        exit_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        exit_shortcut.activated.connect(window.close)
        window._live_desktop_exit_shortcut = exit_shortcut

        logger.info(
            "Icon-hole prototype session=%s Qt=%s geometry=%dx%d%+d%+d",
            session.session_type,
            session.qt_platform,
            geometry.width(),
            geometry.height(),
            geometry.x(),
            geometry.y(),
        )
        logger.info(
            "Gmail hole root=%d,%d local=%d,%d size=%dx%d",
            GMAIL_X,
            GMAIL_Y,
            hole.x(),
            hole.y(),
            hole.width(),
            hole.height(),
        )
        logger.info("Prototype exit shortcut: Ctrl+Alt+Q")

        window.show()
        window.lower()
        return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
