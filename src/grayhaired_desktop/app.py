"""Application entry point for GrayHaired Desktop."""

from __future__ import annotations

import logging
import sys
import time

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication

from grayhaired_desktop.appearance import (
    apply_system_appearance,
    detect_system_appearance,
    palette_appearance,
)
from grayhaired_desktop.config import AppMetadata, create_settings
from grayhaired_desktop.logger import configure_logging, log_file_path
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

    started_at = time.perf_counter()
    logger = configure_logging(logging.INFO)
    logger.info("Log file: %s", log_file_path())
    logger.info("Application startup began")
    metadata = AppMetadata()
    app = build_application(argv)
    system_appearance = detect_system_appearance()
    fallback_applied = apply_system_appearance(app, system_appearance)
    logger.info("System appearance detected: %s", system_appearance.value)
    logger.info(
        "Qt application palette: %s; Qt style: %s; palette fallback: %s",
        palette_appearance(app.palette()).value,
        app.style().objectName(),
        "applied" if fallback_applied else "not needed",
    )
    logger.info("QApplication created after %.3f seconds", time.perf_counter() - started_at)
    settings = create_settings(metadata)
    window = MainWindow(metadata, settings, logger)
    logger.info("Main window created after %.3f seconds", time.perf_counter() - started_at)
    window.show()
    logger.info("Main window shown after %.3f seconds", time.perf_counter() - started_at)
    exit_code = app.exec()
    logger.info("Application closed")
    return exit_code


def main() -> None:
    """Console script wrapper."""

    raise SystemExit(run())


if __name__ == "__main__":
    main()
