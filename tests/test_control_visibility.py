"""Tests for the transient application-control visibility state."""

from grayhaired_desktop.ui.control_visibility import ControlVisibilityState


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
