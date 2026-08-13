"""Static safety checks for the uninstalled GNOME Shell prototype source."""

import json
import os
import re
import shutil
import subprocess
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
        "get_stack_position",
        "set_stack_position",
        "set_child_below_sibling",
        "set_child_above_sibling",
        "set_child_at_index",
        "make_above",
        "unmake_above",
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


def test_managed_client_experiment_uses_gnome_46_ownership_api():
    source = _source()
    config = json.loads((EXTENSION / "managed-client-config.json.example").read_text())

    assert "const MANAGED_CLIENT_EXPERIMENT = false;" in source
    assert "Meta.WaylandClient.new_subprocess(" in source
    assert "Meta.WaylandClient.new(launcher)" in source
    assert "Meta.WaylandClient.new(\n                        global.context, launcher)" in source
    assert source.index("Meta.WaylandClient.new(launcher)") < source.index(
        "Meta.WaylandClient.new(\n                        global.context, launcher)"
    )
    assert "this._managedClient.spawnv(\n                    global.display, config.argv)" in source
    assert "typeof this._managedClient?.spawnv" in source
    assert "typeof this._managedClient?.owns_window" in source
    assert "global.context, launcher, config.argv" in source
    assert "this._managedClient.get_subprocess()" in source
    assert "this._managedClient.owns_window(window)" in source
    assert "query_window_belongs_to" not in source
    assert config["argv"][1:] == ["-m", "grayhaired_desktop.app"]
    assert config["argv"][0].endswith("/.venv/bin/python")


def test_failed_managed_desktop_mutation_is_removed():
    source = _source()

    assert "MANAGED_DESKTOP_SEMANTICS_EXPERIMENT" not in source
    assert "if (owned && identityMatches)" in source
    assert ".hide_from_window_list(" not in source
    assert ".show_in_window_list(" not in source


def test_shell_owned_layer_experiment_only_inserts_its_new_actor():
    source = _source()
    experiment = source.split("    _createShellOwnedLayerTest", 1)[1].split(
        "    _removeShellOwnedLayerTest", 1
    )[0]
    cleanup = source.split("    _removeShellOwnedLayerTest", 1)[1].split(
        "    _logWindowRuntimeApis", 1
    )[0]

    assert "const SHELL_OWNED_LAYER_EXPERIMENT = true;" in source
    assert "new St.BoxLayout" in experiment
    assert "reactive: false" in experiment
    assert "const parent = global.window_group" in experiment
    assert "Main.layoutManager?._backgroundGroup" in experiment
    assert "backgroundGroup.get_parent() !== parent" in experiment
    assert "backgroundIndex + 1" in experiment
    assert experiment.count("parent.insert_child_at_index(actor, backgroundIndex + 1);") == 1
    assert "this._shellOwnedTestActor = actor;" in experiment
    assert "const actor = this._shellOwnedTestActor;" in cleanup
    assert cleanup.count("actor.destroy();") == 1
    assert "RESULT REQUIRES PHYSICAL VISUAL CONFIRMATION" in experiment


def test_managed_client_has_no_ordinary_subprocess_fallback():
    source = _source()

    assert "new Gio.SubprocessLauncher" in source
    assert "Gio.Subprocess.new" not in source
    assert ".spawn(" not in source
    assert "GLib.spawn" not in source
    assert "no supported Meta.WaylandClient constructor" in source
    assert "API path=${apiPath}" in source


def test_managed_client_validates_identity_and_stops_only_its_process():
    source = _source()

    assert "wmClass === GRAYHAIRED_APP_ID" in source
    assert "wmClassInstance === GRAYHAIRED_APP_ID" in source
    assert "const process = this._managedSubprocess;" in source
    assert source.count("process.force_exit();") == 1
    assert "get_pid(" not in source
    assert "GLib.spawn" not in source
    assert "automatic relaunch" not in source


def test_normal_python_startup_does_not_manage_shell_extensions():
    source_root = Path(__file__).parents[1] / "src"
    python_source = "\n".join(
        path.read_text() for path in source_root.rglob("*.py")
    )

    assert "gnome-extensions" not in python_source
    assert "grayhaired-desktop-layer@grayhaired.tech" not in python_source


def test_project_version_remains_0_9_0():
    pyproject = (Path(__file__).parents[1] / "pyproject.toml").read_text()

    assert 'version = "0.9.0"' in pyproject


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
    assert "command -v rg" in collector
    assert "SEARCH_BACKEND='grep fallback'" in collector
    assert "grep -r -l -E --include='*.js'" in collector
    assert "grep -n -E -C 4 -m 18" in collector
    assert "neither ripgrep nor the grep fallback" in collector
    for command in ("sudo ", "rm ", "cp ", "mv ", "gnome-extensions "):
        assert command not in collector


def test_wayland_client_collector_falls_back_when_rg_is_absent(tmp_path):
    collector = (
        Path(__file__).parents[1]
        / "scripts"
        / "collect-zorin-wayland-client-info.sh"
    ).read_text()
    extension_dir = tmp_path / "zorin-desktop-icons@zorinos.com"
    extension_dir.mkdir()
    (extension_dir / "extension.js").write_text(
        "import Meta from 'gi://Meta';\n"
        "\n"
        "launchDesktop() {\n"
        "    waylandClient.query_window_belongs_to(window);\n"
        "}\n"
    )
    test_script = tmp_path / "collector.sh"
    test_script.write_text(
        collector.replace(
            "/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com",
            str(extension_dir),
        )
    )

    fallback_bin = tmp_path / "bin"
    fallback_bin.mkdir()
    for command in ("grep", "sort", "head", "sed", "nl", "cut"):
        (fallback_bin / command).symlink_to(shutil.which(command))

    result = subprocess.run(
        [shutil.which("bash"), str(test_script)],
        check=True,
        capture_output=True,
        text=True,
        env={**os.environ, "PATH": str(fallback_bin)},
    )

    assert "Search backend: grep fallback" in result.stdout
    assert "Matching JavaScript files (1; at most 12 shown)" in result.stdout
    assert "===== extension.js =====" in result.stdout
    assert "extension.js opening/imports (lines 1-140)" in result.stdout
    assert "extension.js launchDesktop body (lines 1-143)" in result.stdout


def test_cooperation_collector_is_fixed_path_bounded_and_read_only():
    collector = (
        Path(__file__).parents[1]
        / "scripts"
        / "collect-zorin-desktop-layer-cooperation-info.sh"
    ).read_text()

    assert (
        "/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com"
        in collector
    )
    assert "maximum 180 output lines" in collector
    assert "grep fallback" in collector
    assert "Gio\\.DBus" in collector
    assert "_backgroundGroup" in collector
    for command in ("sudo ", "rm ", "cp ", "mv ", "gnome-extensions "):
        assert command not in collector


def test_shell_hierarchy_diagnostic_is_observation_only():
    source = _source()
    diagnostic = source.split("    _logShellLayerHierarchy", 1)[1].split(
        "    _createShellOwnedLayerTest", 1
    )[0]
    collector = (
        Path(__file__).parents[1]
        / "scripts"
        / "collect-gnome-shell-layer-hierarchy.sh"
    ).read_text()

    assert "[LayerHierarchy]" in source
    assert "Main.layoutManager?._backgroundGroup" in source
    assert "global.window_group" in source
    assert "global.top_window_group" in source
    for call in (
        ".add_child(",
        ".remove_child(",
        ".insert_child_at_index(",
        ".set_child_above_sibling(",
        ".set_child_below_sibling(",
    ):
        assert call not in diagnostic
    assert "journalctl" in collector
    assert "gjs" not in collector
    assert "tail -n 80" in collector
    for command in ("sudo ", "rm ", "cp ", "mv ", "gnome-extensions "):
        assert command not in collector
