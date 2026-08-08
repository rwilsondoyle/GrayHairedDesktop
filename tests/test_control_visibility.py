"""Tests for the transient application-control visibility state."""

from grayhaired_desktop.ui.control_visibility import (
    ControlVisibilityState,
    apply_control_visibility,
)


def test_controls_start_hidden_and_toggle_both_directions() -> None:
    """A fresh state is clean and supports repeated button toggles."""

    state = ControlVisibilityState()

    assert state.visible is False
    assert state.toggle() is True
    assert state.visible is True
    assert state.toggle() is False
    assert state.visible is False


def test_done_or_escape_can_explicitly_hide_controls() -> None:
    """Explicit visibility requests support the Done and Escape paths."""

    state = ControlVisibilityState()
    state.set_visible(True)

    assert state.set_visible(False) is False
    assert state.visible is False


def test_escape_enabled_state_follows_control_visibility() -> None:
    """Escape handles input only while the application controls are visible."""

    class Target:
        def __init__(self) -> None:
            self.enabled = False

        def setVisible(self, visible: bool) -> None:  # noqa: N802
            self.enabled = visible

        def setEnabled(self, enabled: bool) -> None:  # noqa: N802
            self.enabled = enabled

    state = ControlVisibilityState()
    controls = Target()
    escape = Target()

    apply_control_visibility(state, controls, escape, False)
    assert escape.enabled is False

    apply_control_visibility(state, controls, escape, True)
    assert escape.enabled is True

    apply_control_visibility(state, controls, escape, False)
    assert escape.enabled is False
