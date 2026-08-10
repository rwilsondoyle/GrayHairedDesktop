"""Static safety checks for the uninstalled GNOME Shell prototype source."""

import json
import re
from pathlib import Path


EXTENSION = (
    Path(__file__).parents[1]
    / "gnome-extension"
    / "grayhaired-desktop-layer@grayhaired.tech"
)


def test_prototype_targets_only_gnome_shell_46():
    metadata = json.loads((EXTENSION / "metadata.json").read_text())

    assert metadata["shell-version"] == ["46"]
    assert metadata["uuid"] == "grayhaired-desktop-layer@grayhaired.tech"


def test_prototype_uses_only_verified_stacking_surface():
    source = (EXTENSION / "extension.js").read_text()

    assert ".lower()" in source
    assert "sort_windows_by_stacking" in source
    assert ".get_stack_position(" not in source
    assert ".set_stack_position(" not in source
    assert "setInterval" not in source
    assert "setTimeout" not in source


def test_runtime_api_diagnostic_runs_only_in_shell_context():
    source = (EXTENSION / "extension.js").read_text()
    collector = (
        Path(__file__).parents[1] / "scripts" / "collect-mutter-window-api.sh"
    ).read_text()

    assert "[GrayHaired Desktop Layer][API]" in source
    assert "[GrayHaired Desktop Layer][Phase2]" in source
    assert "typeof window[name]" in source
    assert "typeof global.display[name]" in source
    assert "gjs" not in collector
    assert "journalctl" in collector


def test_actor_diagnostic_path_is_read_only():
    source = (EXTENSION / "extension.js").read_text()
    reconcile = source.split("    _reconcile() {", 1)[1].split(
        "    _runStackingExperiment", 1
    )[0]
    actor_diagnostic = source.split("    _actorType(", 1)[1].split(
        "    _watchWindows", 1
    )[0]
    gray_identity = source.split("function isGrayHairedWindow", 1)[1].split(
        "function isZorinDesktopIconsWindow", 1
    )[0]

    assert "const ACTOR_DIAGNOSTIC_ONLY = true;" in source
    assert "if (ACTOR_DIAGNOSTIC_ONLY)" in reconcile
    assert "this._logActorHierarchy(grayWindow, iconWindows);" in reconcile
    assert "return;" in reconcile.split("if (ACTOR_DIAGNOSTIC_ONLY)", 1)[1]
    assert "get_gtk_application_id" not in gray_identity
    assert "global.display.list_all_windows()" in source
    assert "get_compositor_private()" in actor_diagnostic
    assert "grayAndZorin${index}.sameParent=" in actor_diagnostic
    for method in (
        "lower",
        "raise",
        "stick",
        "unstick",
        "move_resize_frame",
        "move_to_monitor",
        "set_child_below_sibling",
        "set_child_above_sibling",
        "set_child_at_index",
    ):
        assert re.search(rf"\.{method}\s*\(", reconcile + actor_diagnostic) is None


def test_phase_two_has_no_polling_or_unverified_stack_calls():
    source = (EXTENSION / "extension.js").read_text()

    assert re.search(r"\.get_stack_position\s*\(", source) is None
    assert re.search(r"\.set_stack_position\s*\(", source) is None
    assert "setInterval" not in source
    assert "setTimeout" not in source
