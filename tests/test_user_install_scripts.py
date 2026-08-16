"""Sandboxed lifecycle tests for the user-local installer scripts."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).parents[1]


def _fake_python(path: Path) -> None:
    path.write_text(
        """#!/usr/bin/env bash
set -eu
case "${1:-}" in
  */grayhaired-desktop) printf 'installed package launched\n'; exit 0 ;;
esac
if [ "${1:-}" = "-c" ]; then exit 0; fi
if [ "${1:-}" = "-m" ] && [ "${2:-}" = "venv" ] && [ "${3:-}" = "--help" ]; then exit 0; fi
if [ "${1:-}" = "-m" ] && [ "${2:-}" = "venv" ]; then
  mkdir -p "$3/bin"
  cp "$0" "$3/bin/python"
  exit 0
fi
if [ "${1:-}" = "-m" ] && [ "${2:-}" = "pip" ]; then
  printf '#!%s\n# generated console entry point\n' "$0" > "$(dirname "$0")/grayhaired-desktop"
  chmod +x "$(dirname "$0")/grayhaired-desktop"
  exit 0
fi
exit 1
""",
        encoding="utf-8",
    )
    path.chmod(0o755)


def test_install_update_and_uninstall_in_xdg_sandbox(tmp_path):
    fake_python = tmp_path / "python3"
    _fake_python(fake_python)
    home = tmp_path / "home"
    data = home / "data"
    config = home / "config"
    binary = home / "bin"
    env = {
        **os.environ,
        "HOME": str(home),
        "XDG_DATA_HOME": str(data),
        "XDG_CONFIG_HOME": str(config),
        "XDG_BIN_HOME": str(binary),
        "PYTHON": str(fake_python),
    }

    subprocess.run([ROOT / "scripts/install-user.sh"], env=env, check=True)
    launcher = binary / "grayhaired-desktop"
    menu_entry = data / "applications/grayhaired-desktop.desktop"
    console_script = data / "grayhaired-desktop" / "venv" / "bin" / "grayhaired-desktop"
    final_interpreter = data / "grayhaired-desktop" / "venv" / "bin" / "python"
    assert console_script.read_text(encoding="utf-8").splitlines()[0] == (
        f"#!{final_interpreter}"
    )
    assert ".grayhaired-desktop-install." not in console_script.read_text(
        encoding="utf-8"
    )
    assert subprocess.check_output([launcher], text=True) == "installed package launched\n"
    assert f"Exec={launcher}" in menu_entry.read_text(encoding="utf-8")

    # A refresh is idempotent and leaves unrelated preferences untouched.
    preference = config / "GrayHaired Tech" / "GrayHaired Desktop.ini"
    preference.parent.mkdir(parents=True)
    preference.write_text("saved=true\n", encoding="utf-8")
    subprocess.run([ROOT / "scripts/update-user-install.sh"], env=env, check=True)
    assert console_script.read_text(encoding="utf-8").splitlines()[0] == (
        f"#!{final_interpreter}"
    )
    assert subprocess.check_output([launcher], text=True) == "installed package launched\n"
    assert preference.read_text(encoding="utf-8") == "saved=true\n"

    autostart = config / "autostart" / "grayhaired-desktop.desktop"
    autostart.parent.mkdir(parents=True)
    autostart.write_text(
        "[Desktop Entry]\nName=My Desktop\n" f"Exec={launcher}\n",
        encoding="utf-8",
    )
    subprocess.run([ROOT / "scripts/uninstall-user.sh"], env=env, check=True)
    assert not launcher.exists()
    assert not menu_entry.exists()
    assert not (data / "grayhaired-desktop").exists()
    assert not autostart.exists()
    assert preference.exists()


def test_installer_refuses_unowned_launcher(tmp_path):
    fake_python = tmp_path / "python3"
    _fake_python(fake_python)
    home = tmp_path / "home"
    binary = home / "bin"
    binary.mkdir(parents=True)
    launcher = binary / "grayhaired-desktop"
    launcher.write_text("unrelated\n", encoding="utf-8")
    env = {
        **os.environ,
        "HOME": str(home),
        "XDG_DATA_HOME": str(home / "data"),
        "XDG_BIN_HOME": str(binary),
        "PYTHON": str(fake_python),
    }

    result = subprocess.run(
        [ROOT / "scripts/install-user.sh"], env=env, text=True, capture_output=True
    )
    assert result.returncode != 0
    assert "not owned" in result.stderr
    assert launcher.read_text(encoding="utf-8") == "unrelated\n"
