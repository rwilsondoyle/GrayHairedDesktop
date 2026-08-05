"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging

from PySide6.QtCore import QSettings, QSize
from PySide6.QtWidgets import QMainWindow

from grayhaired_desktop.browser import BrowserView
from grayhaired_desktop.config import AppMetadata


class MainWindow(QMainWindow):
    """Native application window hosting the GrayHaired web experience."""

    def __init__(self, metadata: AppMetadata, settings: QSettings, logger: logging.Logger) -> None:
        super().__init__()
        self._metadata = metadata
        self._settings = settings
        self._logger = logger.getChild("mainwindow")
        self._browser = BrowserView(metadata.desktop_url, logger, self)

        self.setWindowTitle(f"{metadata.name} {metadata.version}")
        self.setMinimumSize(QSize(1024, 720))
        self.setCentralWidget(self._browser)
        self._restore_window_state()
        self._browser.load_home()

    def closeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Persist window geometry before closing."""

        self._settings.setValue("mainwindow/geometry", self.saveGeometry())
        self._settings.setValue("mainwindow/windowState", self.saveState())
        self._logger.info("Window state saved")
        super().closeEvent(event)

    def _restore_window_state(self) -> None:
        geometry = self._settings.value("mainwindow/geometry")
        window_state = self._settings.value("mainwindow/windowState")

        if geometry is not None:
            self.restoreGeometry(geometry)
        else:
            self.resize(1280, 800)

        if window_state is not None:
            self.restoreState(window_state)
