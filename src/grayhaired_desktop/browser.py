"""QtWebEngine browser widget for the GrayHaired Desktop web surface."""

from __future__ import annotations

import logging

from PySide6.QtCore import QUrl, Slot
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

        self._logger.info("Loading %s", self._url.toString())
        self.load(self._url)

    @Slot()
    def _on_load_started(self) -> None:
        self._logger.debug("Page load started")

    @Slot(bool)
    def _on_load_finished(self, ok: bool) -> None:
        if ok:
            self._logger.info("Page loaded successfully")
        else:
            self._logger.error("Page failed to load: %s", self._url.toString())
