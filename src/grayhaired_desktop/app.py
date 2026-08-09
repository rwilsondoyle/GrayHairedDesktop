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
from grayhaired_desktop.autostart import installed_launch_executable
from grayhaired_desktop.config import AppMetadata, create_settings
from grayhaired_desktop.desktop_mode import (
    DesktopModePath,
    detect_session,
    select_desktop_mode,
)
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
    session_info = detect_session(app.platformName())
    logger.info(
        "Graphical session: type=%s; Qt platform=%s; desktop=%s",
        session_info.session_type,
        session_info.qt_platform,
        session_info.desktop_environment,
    )
    launch_executable = installed_launch_executable(sys.argv[0])
    window = MainWindow(
        metadata, settings, logger, session_info, launch_executable
    )
    mode_path = window.apply_startup_mode()
    desktop_available = (
        select_desktop_mode(session_info, True) is DesktopModePath.X11_DESKTOP
    )
    logger.info(
        "Desktop Mode available: %s; implementation/fallback: %s",
        "yes" if desktop_available else "no",
        mode_path.value,
    )
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
