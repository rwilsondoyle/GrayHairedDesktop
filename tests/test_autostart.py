"""Tests for the user-level XDG autostart integration."""

from pathlib import Path

import pytest

from grayhaired_desktop.autostart import (
    autostart_entry,
    autostart_path,
    installed_launch_executable,
    set_autostart,
)


def test_path_uses_xdg_config_home():
    path = autostart_path({"XDG_CONFIG_HOME": "/tmp/example-config"})

    assert path == Path("/tmp/example-config/autostart/grayhaired-desktop.desktop")


def test_entry_uses_supplied_installed_launcher_without_user_hardcoding():
    entry = autostart_entry(Path("/opt/app/bin/grayhaired-desktop"))

    assert "Exec=/opt/app/bin/grayhaired-desktop" in entry
    assert "/home/" not in entry


def test_entry_rejects_relative_launcher():
    with pytest.raises(ValueError):
        autostart_entry(Path("grayhaired-desktop"))


def test_source_checkout_virtualenv_is_not_used_for_autostart(tmp_path):
    launcher = tmp_path / "checkout" / ".venv" / "bin" / "grayhaired-desktop"

    assert installed_launch_executable(str(launcher)) is None


def test_packaged_absolute_launcher_is_accepted():
    launcher = installed_launch_executable("/opt/grayhaired/bin/grayhaired-desktop")

    assert launcher == Path("/opt/grayhaired/bin/grayhaired-desktop")


def test_enable_and_disable_are_idempotent(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"
    executable = Path("/opt/app/bin/grayhaired-desktop")

    set_autostart(True, executable, target)
    original = target.read_text(encoding="utf-8")
    set_autostart(True, executable, target)
    assert target.read_text(encoding="utf-8") == original

    set_autostart(False, executable, target)
    set_autostart(False, executable, target)
    assert not target.exists()
