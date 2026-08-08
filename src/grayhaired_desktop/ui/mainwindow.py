"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging

from PySide6.QtCore import QSettings, QSize, Qt, QUrl
from PySide6.QtGui import (
    QDesktopServices,
    QIcon,
    QKeySequence,
    QPainter,
    QPixmap,
    QShortcut,
)
from PySide6.QtWidgets import (
    QHBoxLayout,
    QMainWindow,
    QMessageBox,
    QStatusBar,
    QToolButton,
    QVBoxLayout,
    QWidget,
)

from grayhaired_desktop.browser import BrowserView
from grayhaired_desktop.config import AppMetadata
from grayhaired_desktop.logger import log_file_path
from grayhaired_desktop.settings import load_preferences, save_preferences
from grayhaired_desktop.ui.actions import (
    create_actions,
    register_window_navigation_actions,
)
from grayhaired_desktop.ui.control_visibility import (
    ControlVisibilityState,
    apply_control_visibility,
)
from grayhaired_desktop.ui.favorites import FavoritesWidget
from grayhaired_desktop.ui.menus import create_menus
from grayhaired_desktop.ui.preferences import PreferencesDialog
from grayhaired_desktop.ui.tooltips import install_explicit_tooltips


def _settings_icon(widget: QWidget) -> QIcon:
    """Return the first available settings icon, with a Qt-rendered gear fallback."""

    for icon_name in (
        "preferences-system",
        "settings",
        "configure",
        "system-settings",
    ):
        icon = QIcon.fromTheme(icon_name)
        if not icon.isNull():
            return icon

    pixmap = QPixmap(24, 24)
    pixmap.fill(Qt.GlobalColor.transparent)
    painter = QPainter(pixmap)
    painter.setRenderHint(QPainter.RenderHint.TextAntialiasing)
    painter.setPen(widget.palette().buttonText().color())
    font = painter.font()
    font.setPixelSize(20)
    painter.setFont(font)
    painter.drawText(pixmap.rect(), Qt.AlignmentFlag.AlignCenter, "⚙")
    painter.end()
    return QIcon(pixmap)


class MainWindow(QMainWindow):
    """Native application window hosting the GrayHaired web experience."""

    def __init__(
        self, metadata: AppMetadata, settings: QSettings, logger: logging.Logger
    ) -> None:
        super().__init__()
        self._metadata = metadata
        self._settings = settings
        self._logger = logger.getChild("mainwindow")
        self._preferences = load_preferences(settings)
        self._browser = BrowserView(self._preferences.home_page_url, logger, self)

        self.setWindowTitle("GrayDesk Alpha 0.9")
        self.setMinimumSize(QSize(1024, 720))
        central = QWidget(self)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(8, 8, 8, 6)
        layout.setSpacing(4)
        layout.addWidget(self._browser, 1)

        shortcut_row = QHBoxLayout()
        shortcut_row.setContentsMargins(0, 0, 0, 0)
        shortcut_row.setSpacing(6)
        self._open_controls_button = QToolButton(central)
        self._open_controls_button.setIcon(_settings_icon(self))
        self._open_controls_button.setToolTip("Open controls")
        self._open_controls_button.setAccessibleName("Open controls")
        self._open_controls_button.setAccessibleDescription(
            "Show application controls and settings"
        )
        self._open_controls_button.setMinimumSize(QSize(42, 42))
        self._open_controls_button.setAutoRaise(True)
        self._open_controls_tooltip_filter = install_explicit_tooltips(
            self._open_controls_button
        )
        shortcut_row.addWidget(
            self._open_controls_button, 0, Qt.AlignmentFlag.AlignLeft
        )
        self._favorites = FavoritesWidget(
            settings,
            self._browser.open_external,
            self._preferences.shortcut_theme,
            central,
        )
        shortcut_row.addWidget(self._favorites, 1)
        layout.addLayout(shortcut_row, 0)
        self.setCentralWidget(central)
        self.setStatusBar(QStatusBar(self))
        self.statusBar().showMessage("Ready")

        self._actions = create_actions(
            self,
            close=self.close,
            load_home=lambda: self._browser.load_home("Home action"),
            reload_page=self._browser.reload_desktop,
            show_preferences=self._show_preferences_dialog,
            show_about=self._show_about_dialog,
            open_log_folder=self._open_log_folder,
        )
        self._controls = ControlVisibilityState()
        register_window_navigation_actions(self, self._actions)
        create_menus(self.menuBar(), self._actions, self._hide_controls)
        self._open_controls_button.clicked.connect(self._toggle_controls)
        self._escape_shortcut = QShortcut(QKeySequence.Cancel, self)
        self._escape_shortcut.setContext(Qt.ShortcutContext.WindowShortcut)
        self._escape_shortcut.activated.connect(self._hide_controls)
        self._connect_browser_status()
        self._restore_window_state()
        # restoreState may include obsolete toolbar data from an earlier release.
        # No toolbar is created, and every launch explicitly begins with menus hidden.
        self._set_controls_visible(False)
        self._browser.load_home("initial application load")

    def _set_controls_visible(self, visible: bool) -> None:
        """Apply the transient control state to the menu bar."""

        apply_control_visibility(
            self._controls,
            self.menuBar(),
            self._escape_shortcut,
            visible,
        )

    def _toggle_controls(self) -> None:
        """Show or hide controls from the lower-left button."""

        self._set_controls_visible(not self._controls.visible)

    def _hide_controls(self) -> None:
        """Return focus to the Desktop Website by hiding the controls."""

        if self._controls.visible:
            self._set_controls_visible(False)

    def closeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Persist window geometry before closing."""

        self._settings.setValue("mainwindow/geometry", self.saveGeometry())
        self._settings.setValue("mainwindow/windowState", self.saveState())
        self._logger.info("Window state saved")
        super().closeEvent(event)

    def _connect_browser_status(self) -> None:
        self._browser.loadStarted.connect(self._handle_load_started)
        self._browser.loadFinished.connect(self._update_load_status)
        self._browser.linkOpenFinished.connect(self._update_external_link_status)

    def _handle_load_started(self) -> None:
        self.statusBar().showMessage("Loading...")

    def _update_load_status(self, ok: bool) -> None:
        if ok:
            self.statusBar().showMessage("Loaded")
        else:
            self.statusBar().showMessage("Failed")

    def _update_external_link_status(self, opened: bool) -> None:
        if opened:
            self.statusBar().showMessage("Opened link in the default browser.", 5000)
        else:
            self.statusBar().showMessage(
                "Could not open link in the default browser.", 5000
            )

    def _show_preferences_dialog(self) -> None:
        dialog = PreferencesDialog(self._preferences, self)
        if dialog.exec() != PreferencesDialog.DialogCode.Accepted:
            return

        updated_preferences = dialog.preferences
        self._preferences = updated_preferences
        save_preferences(self._settings, self._preferences)
        self._favorites.set_theme(self._preferences.shortcut_theme)
        self._browser.set_home_url(self._preferences.home_page_url)
        self._browser.load_home("Settings-triggered load")
        self._logger.info("Settings saved")

    def _show_about_dialog(self) -> None:
        QMessageBox.about(
            self,
            "About GrayHaired Desktop",
            (
                f"GrayDesk Alpha 0.9 ({self._metadata.version})\n\n"
                "A native PySide6 desktop shell for the GrayHaired Tech web experience."
            ),
        )

    def _open_log_folder(self) -> None:
        """Open the directory containing the persistent application log."""

        opened = QDesktopServices.openUrl(QUrl.fromLocalFile(str(log_file_path().parent)))
        if not opened:
            self.statusBar().showMessage("Could not open the log folder.", 5000)

    def _restore_window_state(self) -> None:
        geometry = self._settings.value("mainwindow/geometry")
        window_state = self._settings.value("mainwindow/windowState")

        if geometry is not None:
            self.restoreGeometry(geometry)
        else:
            self.resize(1280, 800)

        if window_state is not None:
            self.restoreState(window_state)
