"""State for the temporary application control bar."""

from __future__ import annotations


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
