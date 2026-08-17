"""Safe, snapshot-based GNOME wallpaper support."""

from __future__ import annotations

import logging
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence

from PySide6.QtCore import QObject, QSettings, QSize, QTimer, QUrl, Signal, Qt
from PySide6.QtWidgets import QApplication
from PySide6.QtWebEngineWidgets import QWebEngineView

from grayhaired_desktop.browser import safe_display_url
from grayhaired_desktop.settings import is_valid_home_page_url

BACKGROUND_SCHEMA = "org.gnome.desktop.background"
PICTURE_URI_KEY = "picture-uri"
PICTURE_URI_DARK_KEY = "picture-uri-dark"
PICTURE_OPTIONS_KEY = "picture-options"
PREVIOUS_URI_KEY = "wallpaper/previousPictureUri"
PREVIOUS_URI_DARK_KEY = "wallpaper/previousPictureUriDark"
PREVIOUS_OPTIONS_KEY = "wallpaper/previousPictureOptions"
HAS_PREVIOUS_KEY = "wallpaper/hasPreviousWallpaper"
WALLPAPER_ACTIVE_KEY = "wallpaper/myDesktopWallpaperActive"

CommandRunner = Callable[..., subprocess.CompletedProcess[str]]


@dataclass(frozen=True, slots=True)
class BackgroundSettings:
    """The GNOME background values that Wallpaper Mode may change."""

    picture_uri: str
    picture_uri_dark: str
    picture_options: str | None


def wallpaper_path(home: Path | None = None) -> Path:
    """Return the deterministic user-data path for the generated snapshot."""

    root = (home or Path.home()) / ".local/share/GrayHairedDesktop/wallpaper"
    return root / "my-desktop-wallpaper.png"


def file_uri(path: Path) -> str:
    """Convert a local wallpaper path to an encoded absolute file URI."""

    return path.expanduser().resolve().as_uri()


def _run_gsettings(
    arguments: Sequence[str], runner: CommandRunner = subprocess.run
) -> subprocess.CompletedProcess[str]:
    return runner(
        ["gsettings", *arguments],
        check=True,
        capture_output=True,
        text=True,
    )


def _read_key(key: str, runner: CommandRunner) -> str:
    result = _run_gsettings(("get", BACKGROUND_SCHEMA, key), runner)
    value = result.stdout.strip()
    # gsettings prints strings as a GVariant quoted value. json/shlex parsing is
    # inappropriate for every GVariant, but these keys contain plain strings.
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("\\'", "'").replace("\\\\", "\\")
    return value


def read_background_settings(
    runner: CommandRunner = subprocess.run,
) -> BackgroundSettings:
    """Read only the GNOME background values managed by Wallpaper Mode."""

    return BackgroundSettings(
        picture_uri=_read_key(PICTURE_URI_KEY, runner),
        picture_uri_dark=_read_key(PICTURE_URI_DARK_KEY, runner),
        picture_options=_read_key(PICTURE_OPTIONS_KEY, runner),
    )


def set_background_wallpaper(
    uri: str, runner: CommandRunner = subprocess.run
) -> None:
    """Set both GNOME light and dark wallpaper URIs using fixed arguments."""

    _run_gsettings(("set", BACKGROUND_SCHEMA, PICTURE_URI_KEY, uri), runner)
    _run_gsettings(("set", BACKGROUND_SCHEMA, PICTURE_URI_DARK_KEY, uri), runner)


def restore_background_settings(
    background: BackgroundSettings, runner: CommandRunner = subprocess.run
) -> None:
    """Restore only the GNOME background values previously captured."""

    _run_gsettings(
        ("set", BACKGROUND_SCHEMA, PICTURE_URI_KEY, background.picture_uri), runner
    )
    _run_gsettings(
        ("set", BACKGROUND_SCHEMA, PICTURE_URI_DARK_KEY, background.picture_uri_dark),
        runner,
    )
    if background.picture_options is not None:
        _run_gsettings(
            ("set", BACKGROUND_SCHEMA, PICTURE_OPTIONS_KEY, background.picture_options),
            runner,
        )


def has_previous_wallpaper(settings: QSettings) -> bool:
    value = settings.value(HAS_PREVIOUS_KEY, False)
    return value if isinstance(value, bool) else str(value).lower() in {"1", "true"}


class WallpaperManager:
    """Preserve, apply, and restore wallpaper configuration transactionally."""

    def __init__(
        self,
        settings: QSettings,
        logger: logging.Logger,
        runner: CommandRunner = subprocess.run,
    ) -> None:
        self._settings = settings
        self._logger = logger.getChild("wallpaper")
        self._runner = runner

    def apply(self, image_path: Path) -> bool:
        """Preserve the original configuration once, then apply *image_path*."""

        current: BackgroundSettings | None = None
        try:
            # Capture the immediately-current values for rollback on every
            # operation, while preserving the user's original only once.
            current = read_background_settings(self._runner)
            if not has_previous_wallpaper(self._settings):
                self._settings.setValue(PREVIOUS_URI_KEY, current.picture_uri)
                self._settings.setValue(PREVIOUS_URI_DARK_KEY, current.picture_uri_dark)
                if current.picture_options is not None:
                    self._settings.setValue(PREVIOUS_OPTIONS_KEY, current.picture_options)
                self._settings.setValue(HAS_PREVIOUS_KEY, True)
                self._settings.sync()
            uri = file_uri(image_path)
            set_background_wallpaper(uri, self._runner)
            self._settings.setValue(WALLPAPER_ACTIVE_KEY, True)
            self._settings.sync()
            self._logger.info("GNOME wallpaper updated: %s", image_path)
            return True
        except (OSError, subprocess.SubprocessError) as error:
            self._logger.error("GNOME wallpaper update failed: %s", error)
            # A failure on the second URI could otherwise leave half of the
            # appearance changed. Best-effort rollback uses the just-captured
            # configuration without clearing the user's restore record.
            if current is not None:
                try:
                    restore_background_settings(current, self._runner)
                except (OSError, subprocess.SubprocessError) as rollback_error:
                    self._logger.error("Wallpaper rollback failed: %s", rollback_error)
            return False

    def restore(self) -> bool:
        """Restore and then clear the saved-original marker on success."""

        if not has_previous_wallpaper(self._settings):
            return False
        previous = BackgroundSettings(
            picture_uri=self._settings.value(PREVIOUS_URI_KEY, "", str),
            picture_uri_dark=self._settings.value(PREVIOUS_URI_DARK_KEY, "", str),
            picture_options=(
                self._settings.value(PREVIOUS_OPTIONS_KEY, type=str)
                if self._settings.contains(PREVIOUS_OPTIONS_KEY)
                else None
            ),
        )
        try:
            restore_background_settings(previous, self._runner)
        except (OSError, subprocess.SubprocessError) as error:
            self._logger.error("Previous wallpaper restoration failed: %s", error)
            return False
        self._settings.remove(PREVIOUS_URI_KEY)
        self._settings.remove(PREVIOUS_URI_DARK_KEY)
        self._settings.remove(PREVIOUS_OPTIONS_KEY)
        self._settings.setValue(HAS_PREVIOUS_KEY, False)
        self._settings.setValue(WALLPAPER_ACTIVE_KEY, False)
        self._settings.sync()
        self._logger.info("Previous GNOME wallpaper restored")
        return True


class WallpaperRenderer(QObject):
    """Create one bounded, non-persistent QtWebEngine wallpaper snapshot."""

    finished = Signal(bool, str)

    def __init__(
        self,
        url: str,
        logger: logging.Logger,
        parent: QObject | None = None,
        *,
        load_timeout_ms: int = 30_000,
        settle_delay_ms: int = 1_500,
    ) -> None:
        super().__init__(parent)
        self._url = url
        self._logger = logger.getChild("wallpaper.renderer")
        self._load_timeout_ms = load_timeout_ms
        self._settle_delay_ms = settle_delay_ms
        self._view: QWebEngineView | None = None
        self._done = False
        self._timeout = QTimer(self)
        self._timeout.setSingleShot(True)
        self._timeout.timeout.connect(self._timed_out)

    def start(self) -> None:
        """Start rendering the configured HTTP(S) URL at primary-screen pixels."""

        if not is_valid_home_page_url(self._url):
            self._finish(False, "The saved Desktop Website address is not valid.")
            return
        screen = QApplication.primaryScreen()
        if screen is None:
            self._finish(False, "No screen is available for the wallpaper picture.")
            return
        logical = screen.geometry().size()
        ratio = screen.devicePixelRatio()
        pixels = QSize(round(logical.width() * ratio), round(logical.height() * ratio))
        self._logger.info(
            "Wallpaper render requested: %s; target=%dx%d",
            safe_display_url(QUrl(self._url)),
            pixels.width(),
            pixels.height(),
        )
        self._view = QWebEngineView()
        self._view.setAttribute(Qt.WidgetAttribute.WA_DontShowOnScreen)
        # QWidget geometry is expressed in device-independent pixels. ``grab``
        # returns a pixmap at the screen DPR, producing the logged physical size.
        self._view.setFixedSize(logical)
        self._view.loadFinished.connect(self._loaded)
        self._view.show()
        self._logger.info("Wallpaper render started")
        self._timeout.start(self._load_timeout_ms)
        self._view.load(QUrl(self._url))

    def _loaded(self, ok: bool) -> None:
        self._timeout.stop()
        if not ok:
            self._finish(False, "The Desktop Website could not be loaded.")
            return
        QTimer.singleShot(self._settle_delay_ms, self._capture)

    def _capture(self) -> None:
        if self._done or self._view is None:
            return
        target = wallpaper_path()
        try:
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            os.chmod(target.parent, 0o700)
            image = self._view.grab()
            if image.isNull() or not image.save(str(target), "PNG") or target.stat().st_size == 0:
                target.unlink(missing_ok=True)
                raise OSError("Qt did not produce a complete PNG")
        except OSError as error:
            self._logger.error("Wallpaper image save failed: %s", error)
            self._finish(False, "The wallpaper picture could not be saved.")
            return
        self._logger.info("Wallpaper render completed: %s", target)
        self._finish(True, str(target))

    def _timed_out(self) -> None:
        self._logger.error("Wallpaper render timed out")
        self._finish(False, "The Desktop Website took too long to load.")

    def _finish(self, ok: bool, detail: str) -> None:
        if self._done:
            return
        self._done = True
        self._timeout.stop()
        if self._view is not None:
            self._view.stop()
            self._view.deleteLater()
            self._view = None
        self.finished.emit(ok, detail)
