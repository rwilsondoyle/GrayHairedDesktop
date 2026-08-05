"""Application entry point for GrayHaired Desktop."""

from __future__ import annotations

import logging
import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication

from grayhaired_desktop.config import AppMetadata, create_settings
from grayhaired_desktop.logger import configure_logging
from grayhaired_desktop.ui.mainwindow import MainWindow


def build_application(argv: list[str] | None = None) -> QApplication:
    """Create and configure the QApplication instance."""

    metadata = AppMetadata()
    QApplication.setAttribute(Qt.ApplicationAttribute.AA_DontCreateNativeWidgetSiblings)
    app = QApplication(sys.argv if argv is None else argv)
    app.setApplicationName(metadata.name)
    app.setApplicationVersion(metadata.version)
    app.setOrganizationName(metadata.organization)
    app.setOrganizationDomain(metadata.domain)
    return app


def run(argv: list[str] | None = None) -> int:
    """Run the GrayHaired Desktop application."""

    logger = configure_logging(logging.INFO)
    metadata = AppMetadata()
    app = build_application(argv)
    settings = create_settings(metadata)
    window = MainWindow(metadata, settings, logger)
    window.show()
    logger.info("Application started")
    exit_code = app.exec()
    logger.info("Application closed")
    return exit_code


def main() -> None:
    """Console script wrapper."""

    raise SystemExit(run())


if __name__ == "__main__":
    main()
