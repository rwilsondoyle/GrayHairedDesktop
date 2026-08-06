"""Persistent user preferences for GrayHaired Desktop."""

from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlsplit

from PySide6.QtCore import QSettings

DEFAULT_HOME_PAGE_URL = "https://grayhaired.tech/desktop-c/"
HOME_PAGE_URL_KEY = "preferences/homePageUrl"


def is_valid_home_page_url(value: str) -> bool:
    """Return whether *value* is a complete HTTP or HTTPS web address."""

    if (
        not value
        or value != value.strip()
        or any(character.isspace() for character in value)
    ):
        return False

    try:
        parsed = urlsplit(value)
        # Accessing the port also detects malformed and out-of-range port values.
        parsed.port
    except ValueError:
        return False

    return parsed.scheme.lower() in {"http", "https"} and bool(parsed.hostname)


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
