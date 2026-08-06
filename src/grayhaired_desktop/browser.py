"""QtWebEngine browser widget for the GrayHaired Desktop web surface."""

from __future__ import annotations

import logging

from PySide6.QtCore import QUrl, Slot
from PySide6.QtWebEngineCore import QWebEnginePage
from PySide6.QtWebEngineWidgets import QWebEngineView


class BrowserView(QWebEngineView):
    """Small wrapper around QWebEngineView with logging hooks."""

    def __init__(self, url: str, logger: logging.Logger, parent=None) -> None:
        super().__init__(parent)
        self._logger = logger.getChild("browser")
        self._url = QUrl(url)
        self.loadStarted.connect(self._on_load_started)
        self.loadFinished.connect(self._on_load_finished)

    def load_home(self) -> None:
        """Load the configured GrayHaired Desktop URL."""

        self.load(self._url)

    def set_home_url(self, url: str) -> None:
        """Update the configured home URL."""

        self._url = QUrl(url)

    def createWindow(
        self, window_type: QWebEnginePage.WebWindowType
    ) -> QWebEngineView:
        """Redirect requested browser windows and tabs into this view."""

        self._logger.info(
            "Redirecting new-window request into the existing browser view: %s",
            window_type.name,
        )
        return self

    @Slot()
    def _on_load_started(self) -> None:
        self._logger.info("Loading page: %s", self.url().toString() or self._url.toString())

    @Slot(bool)
    def _on_load_finished(self, ok: bool) -> None:
        if ok:
            self._logger.info("Finished loading")
        else:
            self._logger.error("Load failed: %s", self.url().toString() or self._url.toString())
