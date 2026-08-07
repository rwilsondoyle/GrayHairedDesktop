"""QtWebEngine launch-page widget for the GrayHaired Desktop web surface."""

from __future__ import annotations

import logging
import time

from PySide6.QtCore import QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices
from PySide6.QtWebEngineCore import QWebEnginePage
from PySide6.QtWebEngineWidgets import QWebEngineView


class LaunchPage(QWebEnginePage):
    """Keep the launch page embedded while sending clicked links to the OS."""

    linkOpenFinished = Signal(bool)

    def __init__(self, logger: logging.Logger, parent=None) -> None:
        super().__init__(parent)
        self._logger = logger
        self.newWindowRequested.connect(self._open_new_window_externally)

    def acceptNavigationRequest(
        self,
        url: QUrl,
        navigation_type: QWebEnginePage.NavigationType,
        is_main_frame: bool,
    ) -> bool:
        """Open main-frame link clicks externally, except same-page fragments."""

        if (
            is_main_frame
            and navigation_type == QWebEnginePage.NavigationType.NavigationTypeLinkClicked
            and not self._is_same_page_fragment(url)
        ):
            self.open_external(url)
            return False
        return super().acceptNavigationRequest(url, navigation_type, is_main_frame)

    @Slot(object)
    def _open_new_window_externally(self, request: object) -> None:
        """Handle target=_blank, window.open, tab, and window requests."""

        self.open_external(request.requestedUrl())

    def _is_same_page_fragment(self, destination: QUrl) -> bool:
        if not destination.hasFragment():
            return False
        current = QUrl(self.url())
        target = QUrl(destination)
        current.setFragment("")
        target.setFragment("")
        return current == target

    def open_external(self, url: QUrl) -> None:
        safe_url = safe_display_url(url)
        self._logger.info(
            "Handing external link to the default browser: %s", safe_url
        )
        started_at = time.perf_counter()
        opened = QDesktopServices.openUrl(url)
        elapsed = time.perf_counter() - started_at
        if opened:
            self._logger.info(
                "External link handoff completed in %.3f seconds: %s", elapsed, safe_url
            )
        else:
            self._logger.error(
                "External link handoff failed after %.3f seconds: %s",
                elapsed,
                safe_url,
            )
        self.linkOpenFinished.emit(opened)


def safe_display_url(url: QUrl) -> str:
    """Return a URL suitable for logs, without credentials or query data."""

    safe_url = QUrl(url)
    safe_url.setUserInfo("")
    safe_url.setQuery("")
    safe_url.setFragment("")
    return safe_url.toDisplayString()


class BrowserView(QWebEngineView):
    """Embedded home-page view with logging and external-link handling."""

    linkOpenFinished = Signal(bool)

    def __init__(self, url: str, logger: logging.Logger, parent=None) -> None:
        super().__init__(parent)
        self._logger = logger.getChild("browser")
        self._url = QUrl(url)
        self._load_number = 0
        self._load_started_at: float | None = None
        self._next_load_reason = "initial application load"
        self._active_load_reason = self._next_load_reason
        page = LaunchPage(self._logger, self)
        page.linkOpenFinished.connect(self.linkOpenFinished)
        self.setPage(page)
        self.loadStarted.connect(self._on_load_started)
        self.loadFinished.connect(self._on_load_finished)

    def load_home(self, reason: str = "Home action") -> None:
        """Load the configured GrayHaired Desktop URL."""

        self._next_load_reason = reason
        self.load(self._url)

    def reload_desktop(self) -> None:
        """Reload the Desktop Website and label the diagnostic measurement."""

        self._next_load_reason = "Reload action"
        self.reload()

    def set_home_url(self, url: str) -> None:
        """Update the configured home URL."""

        self._url = QUrl(url)

    def open_external(self, url: str) -> None:
        """Open a website outside the desktop without changing its web surface."""

        self.page().open_external(QUrl(url))

    @Slot()
    def _on_load_started(self) -> None:
        self._load_number += 1
        self._load_started_at = time.perf_counter()
        self._active_load_reason = self._next_load_reason
        self._next_load_reason = "browser-initiated load"
        url = safe_display_url(self.url() if not self.url().isEmpty() else self._url)
        self._logger.info(
            "Desktop Website load #%d started (%s): %s",
            self._load_number,
            self._active_load_reason,
            url,
        )

    @Slot(bool)
    def _on_load_finished(self, ok: bool) -> None:
        elapsed = (
            time.perf_counter() - self._load_started_at
            if self._load_started_at is not None
            else 0.0
        )
        url = safe_display_url(self.url() if not self.url().isEmpty() else self._url)
        if ok:
            self._logger.info(
                "Desktop Website load #%d completed successfully in %.3f seconds (%s): %s",
                self._load_number,
                elapsed,
                self._active_load_reason,
                url,
            )
        else:
            self._logger.error(
                "Desktop Website load #%d failed after %.3f seconds (%s): %s",
                self._load_number,
                elapsed,
                self._active_load_reason,
                url,
            )
