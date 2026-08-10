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

    assert "[GrayHaired Desktop Layer][ActorPhase2]" in source
    assert "typeof window[name]" in source
    assert "typeof global.display[name]" in source
    assert "gjs" not in collector
    assert "journalctl" in collector


def test_actor_experiment_has_one_initial_grayhaired_mutation():
    source = _source()
    experiment = source.split("    _runActorExperiment", 1)[1].split(
        "    _restoreActorOrder", 1
    )[0]

    assert "const ACTOR_EXPERIMENT_MODE = true;" in source
    assert "grayIndex >= 0 && iconIndexes.every(index => index > grayIndex)" in experiment
    assert experiment.count(
        "parent.set_child_below_sibling(grayActor, targetActor);"
    ) == 1
    assert "this._actorMutationAttempted = true;" in experiment
    assert "order changed; not repeating mutation" in experiment
    assert "Actor order already correct" in experiment
    assert "set_child_at_index(" not in source
    assert "set_child_above_sibling(grayActor" not in source
    assert "set_child_below_sibling(targetActor" not in source


def test_actor_experiment_never_mutates_meta_windows_or_polls():
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
    ):
        assert re.search(rf"\.{method}\s*\(", source) is None
    assert "setInterval" not in source
    assert "setTimeout" not in source


def test_actor_experiment_verifies_and_restores_grayhaired_only():
    source = _source()

    assert "sameParentAfter && visible && ordinaryUnchanged" in source
    assert "afterIconIndexes.every(index => index > afterGrayIndex)" in source
    assert "MetaWindowOrder before=" in source
    assert "MetaWindowOrder after=" in source
    assert "parent.set_child_above_sibling(actor, previous);" in source
    assert "parent.set_child_below_sibling(actor, next);" in source
    assert "restore unavailable; log out/in if ordering looks wrong" in source
