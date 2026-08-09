"""Supported Qt/X11 window configuration for Desktop Mode."""

from __future__ import annotations

from typing import Protocol

from PySide6.QtCore import Qt

X11_DESKTOP_ATTRIBUTE = Qt.WidgetAttribute.WA_X11NetWmWindowTypeDesktop
X11_DESKTOP_FLAGS = (
    Qt.WindowType.Window
    | Qt.WindowType.FramelessWindowHint
    | Qt.WindowType.WindowStaysOnBottomHint
)


class WindowConfigurationTarget(Protocol):
    """Small QWidget surface needed by the testable configuration helpers."""

    def setAttribute(
        self, attribute: Qt.WidgetAttribute, on: bool = True
    ) -> None: ...

    def setWindowFlags(self, flags: Qt.WindowType) -> None: ...


def apply_x11_desktop_window(target: WindowConfigurationTarget) -> None:
    """Apply the EWMH desktop attribute before recreating the native window."""

    target.setAttribute(X11_DESKTOP_ATTRIBUTE, True)
    target.setWindowFlags(X11_DESKTOP_FLAGS)


def restore_windowed_window(
    target: WindowConfigurationTarget, normal_flags: Qt.WindowType
) -> None:
    """Clear the EWMH desktop attribute before recreating an ordinary window."""

    target.setAttribute(X11_DESKTOP_ATTRIBUTE, False)
    target.setWindowFlags(normal_flags)
