"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging

from PySide6.QtCore import QSettings, QSize
from PySide6.QtGui import QAction
from PySide6.QtWidgets import QMainWindow, QMessageBox, QStatusBar

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

        self.setWindowTitle("GrayHaired Desktop Alpha 0.2")
        self.setMinimumSize(QSize(1024, 720))
        self.setCentralWidget(self._browser)
        self.setStatusBar(QStatusBar(self))
        self.statusBar().showMessage("Ready")

        self._create_actions()
        self._create_menus()
        self._connect_browser_status()
        self._restore_window_state()
        self._browser.load_home()

    def closeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Persist window geometry before closing."""

        self._settings.setValue("mainwindow/geometry", self.saveGeometry())
        self._settings.setValue("mainwindow/windowState", self.saveState())
        self._logger.info("Window state saved")
        super().closeEvent(event)

    def _create_actions(self) -> None:
        self._exit_action = QAction("Exit", self)
        self._exit_action.setStatusTip("Close GrayHaired Desktop")
        self._exit_action.triggered.connect(self.close)

        self._reload_action = QAction("Reload", self)
        self._reload_action.setStatusTip("Reload the current page")
        self._reload_action.triggered.connect(self._browser.reload)

        self._about_action = QAction("About", self)
        self._about_action.setStatusTip("About GrayHaired Desktop")
        self._about_action.triggered.connect(self._show_about_dialog)

    def _create_menus(self) -> None:
        menu_bar = self.menuBar()

        file_menu = menu_bar.addMenu("File")
        file_menu.addAction(self._exit_action)

        view_menu = menu_bar.addMenu("View")
        view_menu.addAction(self._reload_action)

        help_menu = menu_bar.addMenu("Help")
        help_menu.addAction(self._about_action)

    def _connect_browser_status(self) -> None:
        self._browser.loadStarted.connect(lambda: self.statusBar().showMessage("Page loading"))
        self._browser.loadFinished.connect(self._update_load_status)

    def _update_load_status(self, ok: bool) -> None:
        if ok:
            self.statusBar().showMessage("Page loaded")
        else:
            self.statusBar().showMessage("Page failed")

    def _show_about_dialog(self) -> None:
        QMessageBox.about(
            self,
            "About GrayHaired Desktop",
            (
                "GrayHaired Desktop Alpha 0.2\n\n"
                "A native PySide6 desktop shell for the GrayHaired Tech web experience."
            ),
        )

    def _restore_window_state(self) -> None:
        geometry = self._settings.value("mainwindow/geometry")
        window_state = self._settings.value("mainwindow/windowState")

        if geometry is not None:
            self.restoreGeometry(geometry)
        else:
            self.resize(1280, 800)

        if window_state is not None:
            self.restoreState(window_state)
