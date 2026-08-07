"""QtWebEngine launch-page widget for the GrayHaired Desktop web surface."""

from __future__ import annotations

import logging

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
            self.open_externally(url)
            return False
        return super().acceptNavigationRequest(url, navigation_type, is_main_frame)

    @Slot(object)
    def _open_new_window_externally(self, request: object) -> None:
        """Handle target=_blank, window.open, tab, and window requests."""

        self.open_externally(request.requestedUrl())

    def _is_same_page_fragment(self, destination: QUrl) -> bool:
        if not destination.hasFragment():
            return False
        current = QUrl(self.url())
        target = QUrl(destination)
        current.setFragment("")
        target.setFragment("")
        return current == target

    def open_externally(self, url: QUrl) -> None:
        """Open a destination in the operating system's default web application."""

        safe_url = QUrl(url)
        safe_url.setUserInfo("")
        safe_url.setQuery("")
        safe_url.setFragment("")
        self._logger.info(
            "Opening link in the default browser: %s", safe_url.toDisplayString()
        )
        opened = QDesktopServices.openUrl(url)
        if not opened:
            self._logger.error(
                "Could not open link in the default browser: %s",
                safe_url.toDisplayString(),
            )
        self.linkOpenFinished.emit(opened)


class BrowserView(QWebEngineView):
    """Embedded home-page view with logging and external-link handling."""

    linkOpenFinished = Signal(bool)

    def __init__(self, url: str, logger: logging.Logger, parent=None) -> None:
        super().__init__(parent)
        self._logger = logger.getChild("browser")
        self._url = QUrl(url)
        self._launch_page = LaunchPage(self._logger, self)
        self._launch_page.linkOpenFinished.connect(self.linkOpenFinished)
        self.setPage(self._launch_page)
        self.loadStarted.connect(self._on_load_started)
        self.loadFinished.connect(self._on_load_finished)

    def load_home(self) -> None:
        """Load the configured GrayHaired Desktop URL."""

        self.load(self._url)

    def set_home_url(self, url: str) -> None:
        """Update the configured home URL."""

        self._url = QUrl(url)

    def open_external(self, url: str) -> None:
        """Open a URL externally without changing the embedded Desktop Website."""

        self._launch_page.open_externally(QUrl(url))

    @Slot()
    def _on_load_started(self) -> None:
        self._logger.info("Loading page: %s", self.url().toString() or self._url.toString())

    @Slot(bool)
    def _on_load_finished(self, ok: bool) -> None:
        if ok:
            self._logger.info("Finished loading")
        else:
            self._logger.error("Load failed: %s", self.url().toString() or self._url.toString())
