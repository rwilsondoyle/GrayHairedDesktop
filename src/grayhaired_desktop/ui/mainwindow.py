"""Main Qt window for GrayHaired Desktop."""

from __future__ import annotations

import logging
from pathlib import Path

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
from grayhaired_desktop.autostart import set_autostart
from grayhaired_desktop.config import AppMetadata
from grayhaired_desktop.desktop_mode import (
    DesktopModePath,
    SessionInfo,
    select_desktop_mode,
)
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
from grayhaired_desktop.ui.tooltips import HelpBubble, install_explicit_tooltips


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
        self,
        metadata: AppMetadata,
        settings: QSettings,
        logger: logging.Logger,
        session_info: SessionInfo,
        launch_executable: Path | None,
    ) -> None:
        super().__init__()
        self._metadata = metadata
        self._settings = settings
        self._logger = logger.getChild("mainwindow")
        self._preferences = load_preferences(settings)
        self._session_info = session_info
        self._launch_executable = launch_executable
        self._desktop_mode_active = False
        self._normal_window_flags = self.windowFlags()
        self._normal_geometry = None
        self._browser = BrowserView(self._preferences.home_page_url, logger, self)

        self.setWindowTitle(self._metadata.name)
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
            "Show the File, View, Settings, Help, and Done controls"
        )
        self._open_controls_button.setMinimumSize(QSize(42, 42))
        self._open_controls_button.setAutoRaise(True)
        self._open_controls_help_bubble = HelpBubble(
            self._open_controls_button
        )
        self._open_controls_tooltip_filter = install_explicit_tooltips(
            self._open_controls_button, self._open_controls_help_bubble
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
        self._desktop_recovery_shortcut = QShortcut(QKeySequence("Ctrl+Shift+D"), self)
        self._desktop_recovery_shortcut.setContext(Qt.ShortcutContext.ApplicationShortcut)
        self._desktop_recovery_shortcut.activated.connect(self._leave_desktop_mode)
        self._connect_browser_status()
        self._restore_window_state()
        # restoreState may include obsolete toolbar data from an earlier release.
        # No toolbar is created, and every launch explicitly begins with menus hidden.
        self._set_controls_visible(False)
        self._browser.load_home("initial application load")

    def apply_startup_mode(self) -> DesktopModePath:
        """Apply the requested mode before the window is first shown."""

        return self._apply_desktop_mode(self._preferences.desktop_mode)

    @property
    def desktop_mode_requested(self) -> bool:
        """Return the persisted opt-in state for startup coordination."""

        return self._preferences.desktop_mode

    def _apply_desktop_mode(self, requested: bool) -> DesktopModePath:
        path = select_desktop_mode(self._session_info, requested)
        if path is DesktopModePath.X11_DESKTOP:
            if not self._desktop_mode_active:
                self._normal_geometry = self.saveGeometry()
            self.setWindowFlags(
                Qt.WindowType.Desktop
                | Qt.WindowType.FramelessWindowHint
                | Qt.WindowType.WindowStaysOnBottomHint
            )
            screen = self.screen()
            if screen is not None:
                # One primary/current screen is deliberate: spanning mixed monitor
                # geometries is not reliable without per-screen desktop windows.
                self.setGeometry(screen.geometry())
            self.statusBar().hide()
            self._desktop_mode_active = True
        else:
            self.setWindowFlags(self._normal_window_flags)
            if self._desktop_mode_active and self._normal_geometry is not None:
                self.restoreGeometry(self._normal_geometry)
            self.statusBar().show()
            self._desktop_mode_active = False
        self._logger.info("Desktop Mode path selected: %s", path.value)
        return path

    def show_desktop_mode_fallback(self) -> None:
        """Explain a startup fallback after the ordinary window is visible."""

        QMessageBox.information(
            self,
            "Desktop Mode Unavailable",
            "Desktop Mode is not available in this computer session. "
            "GrayHaired Desktop will open normally instead.",
        )

    def _leave_desktop_mode(self) -> None:
        """Keyboard recovery: persist and return to an ordinary window."""

        if not self._desktop_mode_active:
            return
        self._preferences = type(self._preferences)(
            home_page_url=self._preferences.home_page_url,
            shortcut_theme=self._preferences.shortcut_theme,
            desktop_mode=False,
            autostart=self._preferences.autostart,
        )
        save_preferences(self._settings, self._preferences)
        self._apply_desktop_mode(False)
        self.show()
        self.raise_()
        self.activateWindow()
        self.statusBar().showMessage("Desktop Mode turned off.", 5000)

    def _set_controls_visible(self, visible: bool) -> None:
        """Apply the transient control state to the menu bar."""

        apply_control_visibility(
            self._controls,
            self.menuBar(),
            self._escape_shortcut,
            visible,
        )
        if visible:
            self.menuBar().setFocus(Qt.FocusReason.ShortcutFocusReason)
        else:
            # A hidden menu must not retain focus or intercept subsequent keyboard
            # input intended for the Desktop Website.
            self._browser.setFocus(Qt.FocusReason.ShortcutFocusReason)

    def _toggle_controls(self) -> None:
        """Show or hide controls from the lower-left button."""

        self._set_controls_visible(not self._controls.visible)

    def _hide_controls(self) -> None:
        """Return focus to the Desktop Website by hiding the controls."""

        if self._controls.visible:
            self._set_controls_visible(False)

    def closeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Persist window geometry before closing."""

        if not self._desktop_mode_active:
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
            self.statusBar().showMessage(
                "Desktop Website could not be loaded. Check your connection and "
                "Website Address."
            )

    def _update_external_link_status(self, opened: bool) -> None:
        if opened:
            self.statusBar().showMessage("Opened link in the default browser.", 5000)
        else:
            self.statusBar().showMessage(
                "Could not open the link. Check your default browser and try "
                "again.",
                5000,
            )

    def _show_preferences_dialog(self) -> None:
        dialog = PreferencesDialog(self._preferences, self)
        if dialog.exec() != PreferencesDialog.DialogCode.Accepted:
            return

        updated_preferences = dialog.preferences
        if updated_preferences.autostart != self._preferences.autostart:
            if self._launch_executable is None and updated_preferences.autostart:
                QMessageBox.warning(
                    self,
                    "Could Not Start Automatically",
                    "Automatic start needs the installed GrayHaired Desktop launcher.",
                )
                updated_preferences = type(updated_preferences)(
                    home_page_url=updated_preferences.home_page_url,
                    shortcut_theme=updated_preferences.shortcut_theme,
                    desktop_mode=updated_preferences.desktop_mode,
                    autostart=False,
                )
            else:
                try:
                    set_autostart(
                        updated_preferences.autostart,
                        self._launch_executable or Path("/unavailable"),
                    )
                except OSError as error:
                    self._logger.warning("Autostart update failed: %s", error)
                    QMessageBox.warning(
                        self,
                        "Could Not Change Automatic Start",
                        "GrayHaired Desktop could not change the sign-in setting.",
                    )
                    return
        self._preferences = updated_preferences
        save_preferences(self._settings, self._preferences)
        self._favorites.set_theme(self._preferences.shortcut_theme)
        self._browser.set_home_url(self._preferences.home_page_url)
        self._browser.load_home("Settings-triggered load")
        self._logger.info("Settings saved")
        mode_path = self._apply_desktop_mode(self._preferences.desktop_mode)
        self.show()
        if (
            self._preferences.desktop_mode
            and mode_path is DesktopModePath.UNSUPPORTED
        ):
            QMessageBox.information(
                self,
                "Desktop Mode Unavailable",
                "Desktop Mode is not available in this computer session. "
                "GrayHaired Desktop will open normally instead.",
            )

    def _show_about_dialog(self) -> None:
        QMessageBox.about(
            self,
            "About GrayHaired Desktop",
            (
                f"{self._metadata.name} {self._metadata.version}\n\n"
                "Displays your saved Desktop Website and opens its links and your "
                "shortcuts in the computer's default browser.\n\n"
                "A GrayHaired Tech project."
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
