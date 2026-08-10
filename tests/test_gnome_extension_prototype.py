"""Static safety checks for the uninstalled GNOME Shell prototype source."""

import json
import re
from pathlib import Path


EXTENSION = (
    Path(__file__).parents[1]
    / "gnome-extension"
    / "grayhaired-desktop-layer@grayhaired.tech"
)


def _source() -> str:
    return (EXTENSION / "extension.js").read_text()


def test_prototype_targets_only_gnome_shell_46():
    metadata = json.loads((EXTENSION / "metadata.json").read_text())

    assert metadata["shell-version"] == ["46"]
    assert metadata["uuid"] == "grayhaired-desktop-layer@grayhaired.tech"


def test_runtime_diagnostics_run_only_in_shell_context():
    source = _source()
    collector = (
        Path(__file__).parents[1] / "scripts" / "collect-mutter-window-api.sh"
    ).read_text()

    assert "[GrayHaired Desktop Layer][ActorDiagnostic]" in source
    assert "typeof window[name]" in source
    assert "typeof global.display[name]" in source
    assert "gjs" not in collector
    assert "journalctl" in collector


def test_prototype_is_back_in_safe_investigation_mode():
    source = _source()

    assert "const SAFE_INVESTIGATION_ONLY = true;" in source
    assert "_runActorExperiment" not in source
    assert "_restoreActorOrder" not in source


def test_safe_investigation_never_mutates_windows_or_actors_or_polls():
    source = _source()

    for method in (
        "lower",
        "raise",
        "stick",
        "unstick",
        "move_resize_frame",
        "move_to_monitor",
        "set_type",
        "hide_from_window_list",
        "show_in_window_list",
        "get_stack_position",
        "set_stack_position",
        "set_child_below_sibling",
        "set_child_above_sibling",
        "set_child_at_index",
    ):
        assert re.search(rf"\.{method}\s*\(", source) is None
    assert "setInterval" not in source
    assert "setTimeout" not in source


def test_safe_investigation_uses_read_only_discovery():
    source = _source()

    assert "global.display.list_all_windows()" in source
    assert "global.display.sort_windows_by_stacking(windows)" in source
    assert "window.get_compositor_private()" in source
    assert "grayAndZorin${index}.sameParent=" in source


def test_wayland_client_collector_is_fixed_path_and_read_only():
    collector = (
        Path(__file__).parents[1]
        / "scripts"
        / "collect-zorin-wayland-client-info.sh"
    ).read_text()

    assert (
        "/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com"
        in collector
    )
    assert "query_window_belongs_to" in collector
    for command in ("sudo ", "rm ", "cp ", "mv ", "gnome-extensions "):
        assert command not in collector
