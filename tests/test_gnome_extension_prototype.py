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


def test_phase_two_mutates_only_grayhaired_stacking():
    source = (EXTENSION / "extension.js").read_text()
    experiment = source.split("    _runStackingExperiment", 1)[1].split(
        "    _supportsRelativeStacking", 1
    )[0]
    gray_identity = source.split("function isGrayHairedWindow", 1)[1].split(
        "function isZorinDesktopIconsWindow", 1
    )[0]

    assert "const EXPERIMENT_MODE = true;" in source
    assert source.count("grayWindow.lower();") == 1
    assert ".lower();" not in experiment.replace("grayWindow.lower();", "")
    assert "_applyDesktopGeometry" not in source
    assert "get_gtk_application_id" not in gray_identity
    assert "set_child_above_sibling" not in source
    assert "set_child_below_sibling" not in source
    assert "global.window_group.get_children()" in source
    assert "connect_after(signal, callback)" in source
    assert "this._inspectMappedActor(actor);" in source
    assert "global.display.list_all_windows()" in source
    assert "'window-created', Meta.Display.$gtype" in source
    assert "this._inspectCreatedWindow(window);" in source


def test_phase_two_has_no_polling_or_unverified_stack_calls():
    source = (EXTENSION / "extension.js").read_text()

    assert re.search(r"\.get_stack_position\s*\(", source) is None
    assert re.search(r"\.set_stack_position\s*\(", source) is None
    assert "setInterval" not in source
    assert "setTimeout" not in source
