"""Static safety checks for the uninstalled GNOME Shell prototype source."""

import json
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
    assert "get_stack_position" not in source
    assert "set_stack_position" not in source
    assert "setInterval" not in source
    assert "setTimeout" not in source
