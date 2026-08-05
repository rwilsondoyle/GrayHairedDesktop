"""Persistent user preferences for GrayHaired Desktop."""

from __future__ import annotations

from dataclasses import dataclass

from PySide6.QtCore import QSettings

DEFAULT_HOME_PAGE_URL = "https://grayhaired.tech/desktop-c/"
HOME_PAGE_URL_KEY = "preferences/homePageUrl"


@dataclass(frozen=True, slots=True)
class UserPreferences:
    """User-editable application preferences."""

    home_page_url: str = DEFAULT_HOME_PAGE_URL


def load_preferences(settings: QSettings) -> UserPreferences:
    """Load user preferences from persistent settings."""

    home_page_url = settings.value(HOME_PAGE_URL_KEY, DEFAULT_HOME_PAGE_URL, str)
    return UserPreferences(home_page_url=home_page_url or DEFAULT_HOME_PAGE_URL)


def save_preferences(settings: QSettings, preferences: UserPreferences) -> None:
    """Persist user preferences."""

    settings.setValue(HOME_PAGE_URL_KEY, preferences.home_page_url)
    settings.sync()
