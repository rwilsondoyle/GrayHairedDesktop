"""State for the temporary application control bar."""

from __future__ import annotations

from typing import Protocol


class VisibilityTarget(Protocol):
    """UI surface whose visibility can be changed."""

    def setVisible(self, visible: bool) -> None:  # noqa: N802 - Qt API name
        """Set whether the surface is visible."""


class EnabledTarget(Protocol):
    """Shortcut-like object whose enabled state can be changed."""

    def setEnabled(self, enabled: bool) -> None:  # noqa: N802 - Qt API name
        """Set whether the target can handle input."""


class ControlVisibilityState:
    """Track control visibility without persisting it between application runs."""

    def __init__(self) -> None:
        self._visible = False

    @property
    def visible(self) -> bool:
        """Return whether the controls should currently be shown."""

        return self._visible

    def set_visible(self, visible: bool) -> bool:
        """Set and return the requested visibility."""

        self._visible = visible
        return self._visible

    def toggle(self) -> bool:
        """Toggle and return the requested visibility."""

        return self.set_visible(not self._visible)


def apply_control_visibility(
    state: ControlVisibilityState,
    controls: VisibilityTarget,
    escape_shortcut: EnabledTarget,
    visible: bool,
) -> None:
    """Show or hide controls and enable Escape only while they are visible."""

    effective_visibility = state.set_visible(visible)
    controls.setVisible(effective_visibility)
    escape_shortcut.setEnabled(effective_visibility)
