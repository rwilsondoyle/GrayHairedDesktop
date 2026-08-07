"""Persistent desktop shortcut data."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from typing import Sequence

from PySide6.QtCore import QSettings


@dataclass(frozen=True, slots=True)
class Favorite:
    """A user-defined website shortcut."""

    title: str
    website_address: str
    icon_placeholder: str | None = None


STARTER_FAVORITES = (
    Favorite("Gmail", "https://mail.google.com", "✉"),
    Favorite("Weather", "https://weather.com", "☀"),
    Favorite("News", "https://news.google.com", "▤"),
    Favorite("YouTube", "https://www.youtube.com", "▶"),
    Favorite("Facebook", "https://www.facebook.com", "☺"),
    Favorite("Shopping", "https://www.amazon.com", "🛒"),
    Favorite("FamilySearch", "https://www.familysearch.org", "♥"),
)


def save_favorites(settings: QSettings, favorites: Sequence[Favorite]) -> None:
    """Persist the complete ordered shortcut list."""

    settings.setValue("favorites/items", json.dumps([asdict(item) for item in favorites]))
    settings.setValue("favorites/initialized", True)
    settings.sync()


def load_favorites(settings: QSettings) -> list[Favorite]:
    """Load shortcuts, installing starter examples on first use only."""

    if not settings.contains("favorites/initialized"):
        favorites = list(STARTER_FAVORITES)
        save_favorites(settings, favorites)
        return favorites

    try:
        payload = json.loads(str(settings.value("favorites/items", "[]")))
        if not isinstance(payload, list):
            return []
        favorites = []
        for item in payload:
            if not isinstance(item, dict):
                return []
            title = item["title"]
            address = item["website_address"]
            icon = item.get("icon_placeholder")
            if not isinstance(title, str) or not isinstance(address, str):
                return []
            if icon is not None and not isinstance(icon, str):
                return []
            favorites.append(Favorite(title, address, icon))
        return favorites
    except (KeyError, TypeError, ValueError, json.JSONDecodeError):
        return []
