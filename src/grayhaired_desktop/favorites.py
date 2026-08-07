"""Data model and initial placeholder data for desktop favorites."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Favorite:
    """A website that can be presented as a desktop favorite."""

    title: str
    website_address: str
    icon_placeholder: str | None = None


PLACEHOLDER_FAVORITES = tuple(
    Favorite(title=title, website_address="", icon_placeholder=icon)
    for title, icon in (
        ("Email", "✉"),
        ("Weather", "☀"),
        ("News", "▤"),
        ("YouTube", "▶"),
        ("Facebook", "☺"),
        ("Shopping", "🛒"),
        ("Family", "♥"),
        ("Add Favorite", "+"),
    )
)
