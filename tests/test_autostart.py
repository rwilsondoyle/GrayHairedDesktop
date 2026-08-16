"""Tests for the user-level XDG autostart integration."""

from pathlib import Path

import pytest

from grayhaired_desktop.autostart import (
    autostart_entry,
    autostart_path,
    installed_launch_executable,
    reconcile_autostart,
    set_autostart,
)


def test_path_uses_xdg_config_home():
    path = autostart_path({"XDG_CONFIG_HOME": "/tmp/example-config"})

    assert path == Path("/tmp/example-config/autostart/grayhaired-desktop.desktop")


def test_entry_uses_supplied_installed_launcher_without_user_hardcoding():
    entry = autostart_entry(Path("/opt/app/bin/grayhaired-desktop"))

    assert "Exec=/opt/app/bin/grayhaired-desktop" in entry
    assert "Name=My Desktop" in entry
    assert "/home/" not in entry


def test_entry_rejects_relative_launcher():
    with pytest.raises(ValueError):
        autostart_entry(Path("grayhaired-desktop"))


def test_source_checkout_virtualenv_is_not_used_for_autostart(tmp_path):
    launcher = tmp_path / "checkout" / ".venv" / "bin" / "grayhaired-desktop"

    assert installed_launch_executable(str(launcher)) is None



def test_installed_wrapper_supplies_stable_public_launcher():
    launcher = installed_launch_executable(
        "/home/user/.local/share/grayhaired-desktop/venv/bin/grayhaired-desktop",
        {"GRAYHAIRED_DESKTOP_LAUNCHER": "/home/user/.local/bin/grayhaired-desktop"},
    )

    assert launcher == Path("/home/user/.local/bin/grayhaired-desktop")

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


def test_enabled_correct_entry_is_not_rewritten(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"
    executable = Path("/opt/app/bin/grayhaired-desktop")
    assert reconcile_autostart(True, executable, target) is True
    original_stat = target.stat()

    assert reconcile_autostart(True, executable, target) is False
    assert target.stat().st_mtime_ns == original_stat.st_mtime_ns


def test_enabled_missing_entry_is_recreated(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"
    executable = Path("/opt/app/bin/grayhaired-desktop")

    assert reconcile_autostart(True, executable, target) is True
    assert f"Exec={executable}" in target.read_text(encoding="utf-8")


def test_enabled_stale_launcher_is_repaired(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"
    target.parent.mkdir()
    target.write_text(
        autostart_entry(Path("/opt/old/bin/grayhaired-desktop")), encoding="utf-8"
    )
    current = Path("/opt/current/bin/grayhaired-desktop")

    assert reconcile_autostart(True, current, target) is True
    contents = target.read_text(encoding="utf-8")
    assert f"Exec={current}" in contents
    assert "/opt/old" not in contents


def test_enabled_damaged_entry_is_repaired(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"
    target.parent.mkdir()
    target.write_bytes(b"\xffnot valid utf-8")
    current = Path("/opt/current/bin/grayhaired-desktop")

    assert reconcile_autostart(True, current, target) is True
    assert target.read_text(encoding="utf-8") == autostart_entry(current)


def test_enabled_preference_without_stable_launcher_remains_safe(tmp_path):
    target = tmp_path / "autostart" / "grayhaired-desktop.desktop"

    assert reconcile_autostart(True, None, target) is False
    assert not target.exists()
