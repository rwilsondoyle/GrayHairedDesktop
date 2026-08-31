#!/usr/bin/env python3
"""Temporary X11 Live Desktop experiment with a real desktop-icon zone.

This prototype keeps the existing frameless, stays-below Live Desktop window but
removes a full-height strip from the left side of the top-level Qt window mask.
On X11, pixels and pointer input outside the mask belong to windows underneath,
allowing the untouched Zorin/DING desktop icons to show through and receive
normal clicks, context menus, and drag/drop behavior.

This is research only, not product code.
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

# First physical X11 experiment: reserve the left side for normal Zorin/DING
# desktop icons.  The width is intentionally generous enough for one or two
# icon columns and for dragging between grid positions without crossing back
# into the Live Desktop window.
ICON_ZONE_WIDTH = 220


def copy_settings(source: QSettings, destination: QSettings) -> None:
    """Copy current settings into an isolated prototype store."""

    for key in source.allKeys():
        destination.setValue(key, source.value(key))
    destination.setValue("preferences/autostart", False)
    destination.setValue("preferences/desktopMode", False)
    destination.sync()


def main() -> int:
    metadata = AppMetadata()
    logger = configure_logging(logging.INFO).getChild("live-desktop-x11-icon-zone")
    app = build_application(sys.argv)
    session = detect_session(app.platformName())

    if session.session_type not in {"x11", "xorg"} or session.qt_platform != "xcb":
        logger.error(
            "Icon-zone prototype requires native X11/xcb; session=%s Qt=%s",
            session.session_type,
            session.qt_platform,
        )
        return 2

    with tempfile.TemporaryDirectory(prefix="grayhaired-live-desktop-zone-") as directory:
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
            logger.error("No screen is available for the icon-zone prototype")
            return 2

        geometry = screen.availableGeometry()
        window.setGeometry(geometry)

        # Remove the entire left-side strip from the Live Desktop window.
        # Zorin/DING owns both pixels and pointer input in this region.
        icon_zone = QRect(0, 0, min(ICON_ZONE_WIDTH, geometry.width()), geometry.height())
        full_region = QRegion(window.rect())
        visible_region = full_region.subtracted(QRegion(icon_zone))
        window.setMask(visible_region)

        exit_shortcut = QShortcut(QKeySequence("Ctrl+Alt+Q"), window)
        exit_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        exit_shortcut.activated.connect(window.close)
        window._live_desktop_exit_shortcut = exit_shortcut

        logger.info(
            "Icon-zone prototype session=%s Qt=%s geometry=%dx%d%+d%+d",
            session.session_type,
            session.qt_platform,
            geometry.width(),
            geometry.height(),
            geometry.x(),
            geometry.y(),
        )
        logger.info(
            "Zorin/DING icon zone local=0,0 size=%dx%d",
            icon_zone.width(),
            icon_zone.height(),
        )
        logger.info("Prototype exit shortcut: Ctrl+Alt+Q")

        window.show()
        window.lower()
        return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
