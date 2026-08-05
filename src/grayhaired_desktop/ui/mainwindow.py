"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging

from PySide6.QtCore import QSettings, QSize
from PySide6.QtGui import QAction
from PySide6.QtWidgets import QMainWindow, QMessageBox, QStatusBar, QToolBar

from grayhaired_desktop.browser import BrowserView
from grayhaired_desktop.config import AppMetadata
from grayhaired_desktop.settings import load_preferences, save_preferences
from grayhaired_desktop.ui.preferences import PreferencesDialog


class MainWindow(QMainWindow):
    """Native application window hosting the GrayHaired web experience."""

    def __init__(self, metadata: AppMetadata, settings: QSettings, logger: logging.Logger) -> None:
        super().__init__()
        self._metadata = metadata
        self._settings = settings
        self._logger = logger.getChild("mainwindow")
        self._preferences = load_preferences(settings)
        self._browser = BrowserView(self._preferences.home_page_url, logger, self)

        self.setWindowTitle("GrayDesk Alpha 0.3")
        self.setMinimumSize(QSize(1024, 720))
        self.setCentralWidget(self._browser)
        self.setStatusBar(QStatusBar(self))
        self.statusBar().showMessage("Ready")

        self._create_actions()
        self._create_menus()
        self._create_toolbar()
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

        self._home_action = QAction("Home", self)
        self._home_action.setStatusTip("Load the configured home page")
        self._home_action.triggered.connect(self._browser.load_home)

        self._reload_action = QAction("Reload", self)
        self._reload_action.setStatusTip("Reload the current page")
        self._reload_action.triggered.connect(self._browser.reload)

        self._preferences_action = QAction("Preferences...", self)
        self._preferences_action.setIconText("Preferences")
        self._preferences_action.setStatusTip("Edit GrayHaired Desktop preferences")
        self._preferences_action.triggered.connect(self._show_preferences_dialog)

        self._about_action = QAction("About", self)
        self._about_action.setStatusTip("About GrayHaired Desktop")
        self._about_action.triggered.connect(self._show_about_dialog)

    def _create_menus(self) -> None:
        menu_bar = self.menuBar()

        file_menu = menu_bar.addMenu("File")
        file_menu.addAction(self._exit_action)

        view_menu = menu_bar.addMenu("View")
        view_menu.addAction(self._home_action)
        view_menu.addAction(self._reload_action)

        settings_menu = menu_bar.addMenu("Settings")
        settings_menu.addAction(self._preferences_action)

        help_menu = menu_bar.addMenu("Help")
        help_menu.addAction(self._about_action)

    def _create_toolbar(self) -> None:
        toolbar = QToolBar("Main Toolbar", self)
        toolbar.setMovable(False)
        toolbar.addAction(self._home_action)
        toolbar.addAction(self._reload_action)
        toolbar.addAction(self._preferences_action)
        self.addToolBar(toolbar)

    def _connect_browser_status(self) -> None:
        self._browser.loadStarted.connect(lambda: self.statusBar().showMessage("Loading..."))
        self._browser.loadFinished.connect(self._update_load_status)

    def _update_load_status(self, ok: bool) -> None:
        if ok:
            self.statusBar().showMessage("Loaded")
        else:
            self.statusBar().showMessage("Failed")

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
                "GrayDesk Alpha 0.3\n\n"
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
