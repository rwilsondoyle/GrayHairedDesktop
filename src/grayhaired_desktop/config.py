"""Application configuration and metadata."""

from __future__ import annotations

from dataclasses import dataclass

from PySide6.QtCore import QSettings

from grayhaired_desktop import __app_name__, __domain__, __organization__, __version__


@dataclass(frozen=True, slots=True)
class AppMetadata:
    """Static metadata used by Qt, logging, and packaging."""

    name: str = __app_name__
    version: str = __version__
    organization: str = __organization__
    domain: str = __domain__
    desktop_url: str = "https://grayhaired.tech/desktop-c/"


def create_settings(metadata: AppMetadata) -> QSettings:
    """Create a QSettings instance scoped to the application."""

    QSettings.setDefaultFormat(QSettings.Format.IniFormat)
    return QSettings(metadata.organization, metadata.name)
