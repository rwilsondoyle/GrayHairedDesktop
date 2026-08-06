"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging

from PySide6.QtCore import QSettings, QSize
from PySide6.QtWidgets import QMainWindow, QMessageBox, QStatusBar

from grayhaired_desktop.browser import BrowserView
from grayhaired_desktop.config import AppMetadata
from grayhaired_desktop.settings import load_preferences, save_preferences
from grayhaired_desktop.ui.actions import create_actions
from grayhaired_desktop.ui.menus import create_menus
from grayhaired_desktop.ui.preferences import PreferencesDialog
from grayhaired_desktop.ui.toolbar import create_toolbar


class MainWindow(QMainWindow):
    """Native application window hosting the GrayHaired web experience."""

    def __init__(self, metadata: AppMetadata, settings: QSettings, logger: logging.Logger) -> None:
        super().__init__()
        self._metadata = metadata
        self._settings = settings
        self._logger = logger.getChild("mainwindow")
        self._preferences = load_preferences(settings)
        self._browser = BrowserView(self._preferences.home_page_url, logger, self)

        self.setWindowTitle("GrayDesk Alpha 0.4")
        self.setMinimumSize(QSize(1024, 720))
        self.setCentralWidget(self._browser)
        self.setStatusBar(QStatusBar(self))
        self.statusBar().showMessage("Ready")

        self._actions = create_actions(
            self,
            close=self.close,
            go_back=self._browser.back,
            go_forward=self._browser.forward,
            load_home=self._browser.load_home,
            reload_page=self._browser.reload,
            show_preferences=self._show_preferences_dialog,
            show_about=self._show_about_dialog,
        )
        create_menus(self.menuBar(), self._actions)
        self._toolbar = create_toolbar(self, self._actions)
        self._connect_browser_status()
        self._restore_window_state()
        self._browser.load_home()

    def closeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Persist window geometry before closing."""

        self._settings.setValue("mainwindow/geometry", self.saveGeometry())
        self._settings.setValue("mainwindow/windowState", self.saveState())
        self._logger.info("Window state saved")
        super().closeEvent(event)

    def _connect_browser_status(self) -> None:
        self._browser.loadStarted.connect(self._handle_load_started)
        self._browser.loadFinished.connect(self._update_load_status)
        self._browser.urlChanged.connect(self._update_navigation_actions)

    def _handle_load_started(self) -> None:
        self.statusBar().showMessage("Loading...")
        self._update_navigation_actions()

    def _update_load_status(self, ok: bool) -> None:
        if ok:
            self.statusBar().showMessage("Loaded")
        else:
            self.statusBar().showMessage("Failed")
        self._update_navigation_actions()

    def _update_navigation_actions(self, *_args: object) -> None:
        """Keep navigation controls in sync with the browser history."""

        history = self._browser.history()
        self._actions.back.setEnabled(history.canGoBack())
        self._actions.forward.setEnabled(history.canGoForward())

    def _show_preferences_dialog(self) -> None:
        dialog = PreferencesDialog(self._preferences, self)
        if dialog.exec() != PreferencesDialog.DialogCode.Accepted:
            return

        updated_preferences = dialog.preferences
        if updated_preferences == self._preferences:
            return

        self._preferences = updated_preferences
        save_preferences(self._settings, self._preferences)
        self._browser.set_home_url(self._preferences.home_page_url)
        self._logger.info("Preferences changed")

    def _show_about_dialog(self) -> None:
        QMessageBox.about(
            self,
            "About GrayHaired Desktop",
            (
                "GrayDesk Alpha 0.4\n\n"
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
