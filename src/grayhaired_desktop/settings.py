"""Persistent user preferences for My Desktop."""

from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlsplit

from PySide6.QtCore import QSettings

DEFAULT_HOME_PAGE_URL = "https://grayhaired.tech/desktop-c/"
HOME_PAGE_URL_KEY = "preferences/homePageUrl"
SHORTCUT_THEME_KEY = "preferences/shortcutTheme"
DESKTOP_MODE_KEY = "preferences/desktopMode"
AUTOSTART_KEY = "preferences/autostart"
DEFAULT_SHORTCUT_THEME = "system"
VALID_SHORTCUT_THEMES = {"system", "light", "dark"}


@dataclass(frozen=True, slots=True)
class BuiltInWebsite:
    """A website offered as a ready-to-use desktop choice."""

    display_name: str
    address: str


BUILT_IN_WEBSITES = (
    BuiltInWebsite("Bing", "https://www.bing.com"),
    BuiltInWebsite("DuckDuckGo", "https://duckduckgo.com"),
    BuiltInWebsite("Google", "https://www.google.com"),
    BuiltInWebsite("MSN", "https://www.msn.com"),
    BuiltInWebsite("Yahoo", "https://www.yahoo.com"),
)


def find_built_in_website(address: str) -> BuiltInWebsite | None:
    """Return the built-in website matching *address*, if one exists."""

    return next(
        (website for website in BUILT_IN_WEBSITES if website.address == address), None
    )


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
    shortcut_theme: str = DEFAULT_SHORTCUT_THEME
    desktop_mode: bool = False
    autostart: bool = False


def _setting_bool(settings: QSettings, key: str) -> bool:
    """Read a bool consistently from native and INI QSettings backends."""

    value = settings.value(key, False)
    return value if isinstance(value, bool) else str(value).lower() in {"1", "true", "yes"}


def load_preferences(settings: QSettings) -> UserPreferences:
    """Load user preferences from persistent settings."""

    home_page_url = settings.value(HOME_PAGE_URL_KEY, DEFAULT_HOME_PAGE_URL, str)
    shortcut_theme = settings.value(
        SHORTCUT_THEME_KEY, DEFAULT_SHORTCUT_THEME, str
    ).lower()
    if shortcut_theme not in VALID_SHORTCUT_THEMES:
        shortcut_theme = DEFAULT_SHORTCUT_THEME
    return UserPreferences(
        home_page_url=home_page_url or DEFAULT_HOME_PAGE_URL,
        shortcut_theme=shortcut_theme,
        # This retained key predates the supported windowed product. Never let a
        # legacy true value reactivate the experimental Desktop Mode path.
        desktop_mode=False,
        autostart=_setting_bool(settings, AUTOSTART_KEY),
    )


def save_preferences(settings: QSettings, preferences: UserPreferences) -> None:
    """Persist user preferences."""

    settings.setValue(HOME_PAGE_URL_KEY, preferences.home_page_url)
    settings.setValue(SHORTCUT_THEME_KEY, preferences.shortcut_theme)
    settings.setValue(DESKTOP_MODE_KEY, False)
    settings.setValue(AUTOSTART_KEY, preferences.autostart)
    settings.sync()
