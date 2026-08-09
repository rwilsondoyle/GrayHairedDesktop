"""Conservative Qt/X11 below-normal-window strategy for Desktop Mode."""

from __future__ import annotations

from typing import Protocol

from PySide6.QtCore import Qt

X11_DESKTOP_ATTRIBUTE = Qt.WidgetAttribute.WA_X11NetWmWindowTypeDesktop
X11_BELOW_WINDOW_FLAGS = (
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

    def setGeometry(self, geometry) -> None: ...


class ScreenTarget(Protocol):
    """QScreen surface used to choose panel-preserving work-area geometry."""

    def availableGeometry(self): ...


def apply_x11_below_window(target: WindowConfigurationTarget) -> None:
    """Create a visible normal window with frameless and stays-below hints."""

    # GNOME already owns the EWMH desktop layer and obscures other desktop-type
    # windows. Clear that classification before recreating a normal, below window.
    target.setAttribute(X11_DESKTOP_ATTRIBUTE, False)
    target.setWindowFlags(X11_BELOW_WINDOW_FLAGS)


def restore_windowed_window(
    target: WindowConfigurationTarget, normal_flags: Qt.WindowType
) -> None:
    """Clear the EWMH desktop attribute before recreating an ordinary window."""

    target.setAttribute(X11_DESKTOP_ATTRIBUTE, False)
    target.setWindowFlags(normal_flags)


def apply_x11_work_area(
    target: WindowConfigurationTarget, screen: ScreenTarget
):
    """Fill the screen work area so shell panels remain reachable."""

    geometry = screen.availableGeometry()
    target.setGeometry(geometry)
    return geometry
