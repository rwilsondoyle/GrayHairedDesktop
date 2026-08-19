#!/usr/bin/env python3
"""Temporary cross-session Live Desktop icon-zone experiment.

This prototype keeps the existing frameless, stays-below Live Desktop window but
removes a left-side rectangle from the top-level Qt window mask. The purpose is
to test whether the same real Zorin/DING desktop-icon zone that worked on X11
also works on Wayland.

This is research only. It does not modify Zorin/DING or the user's real My
Desktop settings.
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
    logger = configure_logging(logging.INFO).getChild("live-desktop-icon-zone")
    app = build_application(sys.argv)
    session = detect_session(app.platformName())

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

        zone = QRect(0, 0, min(ICON_ZONE_WIDTH, geometry.width()), geometry.height())
        full_region = QRegion(window.rect())
        visible_region = full_region.subtracted(QRegion(zone))
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
            "Left icon zone local=0,0 size=%dx%d",
            zone.width(),
            zone.height(),
        )
        logger.info("Prototype exit shortcut: Ctrl+Alt+Q")

        window.show()
        window.lower()
        return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
