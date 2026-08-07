"""Logging setup for GrayHaired Desktop."""

from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

_LOG_FORMAT = "%(asctime)s %(levelname)s [%(name)s] %(message)s"
_LOG_DIRECTORY = Path(".local/state/GrayHairedDesktop")
_LOG_FILENAME = "grayhaired-desktop.log"


def log_file_path() -> Path:
    """Return the per-user persistent log path without requiring privileges."""

    return Path.home() / _LOG_DIRECTORY / _LOG_FILENAME


def configure_logging(level: int = logging.INFO) -> logging.Logger:
    """Configure application logging once and return the root app logger."""

    logger = logging.getLogger("grayhaired_desktop")
    logger.setLevel(level)

    formatter = logging.Formatter(_LOG_FORMAT)
    if not any(getattr(handler, "_graydesk_stdout", False) for handler in logger.handlers):
        stream_handler = logging.StreamHandler(sys.stdout)
        stream_handler._graydesk_stdout = True  # type: ignore[attr-defined]
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

    logger.propagate = False
    path = log_file_path()
    if not any(
        isinstance(handler, RotatingFileHandler)
        and Path(handler.baseFilename) == path
        for handler in logger.handlers
    ):
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            file_handler = RotatingFileHandler(
                path, maxBytes=1024 * 1024, backupCount=3, encoding="utf-8"
            )
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
        except OSError as error:
            logger.warning("Persistent log file could not be enabled: %s", error)

    return logger
