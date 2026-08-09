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
    assert "typeof window[name]" in source
    assert "typeof global.display[name]" in source
    assert "gjs" not in collector
    assert "journalctl" in collector


def test_diagnostic_only_reconciliation_cannot_mutate_windows():
    source = (EXTENSION / "extension.js").read_text()
    reconcile = source.split("    _reconcile() {", 1)[1].split(
        "    _runStackingExperiment", 1
    )[0]
    diagnostic_guard = reconcile.index("if (DIAGNOSTIC_ONLY)")
    experiment_call = reconcile.index("this._runStackingExperiment")
    disable = source.split("    disable() {", 1)[1].split("    _connect(", 1)[0]

    assert "const DIAGNOSTIC_ONLY = true;" in source
    assert diagnostic_guard < experiment_call
    assert "return;" in reconcile[diagnostic_guard:experiment_call]
    assert "if (!DIAGNOSTIC_ONLY)\n            this._restoreOrdinaryWindow();" in disable
    assert "global.window_group.get_children()" in source
    assert "connect_after(signal, callback)" in source
    assert "this._inspectMappedActor(actor);" in source
    assert "set_child_above_sibling" not in source
    assert "set_child_below_sibling" not in source
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
    ):
        assert re.search(rf"\.{method}\s*\(", reconcile) is None
