"""Desktop launcher tests use temporary Desktop directories exclusively."""

from __future__ import annotations

import logging
import stat
import subprocess
import pytest

from grayhaired_desktop.desktop_shortcuts import (
    MANAGED_MARKER,
    DesktopShortcutManager,
    launcher_contents,
    launcher_slug,
    resolve_desktop_directory,
    safe_web_url,
)
from grayhaired_desktop.favorites import Favorite


def completed(stdout: str) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess([], 0, stdout, "")


def test_xdg_desktop_resolution_creates_valid_directory(tmp_path):
    target = tmp_path / "My Desktop"
    resolved = resolve_desktop_directory(tmp_path, runner=lambda *a, **k: completed(f"{target}\n"))
    assert resolved == target
    assert resolved.is_dir()


@pytest.mark.parametrize("output", ["", "/tmp/outside", ".", "relative/Desktop"])
def test_resolution_falls_back_and_remains_inside_home(tmp_path, output):
    resolved = resolve_desktop_directory(tmp_path, runner=lambda *a, **k: completed(output))
    assert resolved == tmp_path / "Desktop"
    assert resolved.is_relative_to(tmp_path)


def test_resolution_falls_back_when_xdg_command_is_unavailable(tmp_path):
    def unavailable(*args, **kwargs):
        raise FileNotFoundError
    assert resolve_desktop_directory(tmp_path, runner=unavailable) == tmp_path / "Desktop"


def test_slug_is_safe_and_deterministic():
    assert launcher_slug("  Café / Weather!? ") == "cafe-weather"
    assert launcher_slug("💻") == "shortcut"


def test_launcher_format_uses_safe_helper_without_a_shell():
    text = launcher_contents(Favorite("Gmail\nUnsafe", "https://example.com/a?q=1"), "/home/me/grayhaired-desktop")
    assert "Type=Application" in text
    assert "Name=Gmail Unsafe" in text
    assert MANAGED_MARKER in text
    assert 'Exec="/home/me/grayhaired-desktop" --open-url "https://example.com/a?q=1"' in text
    assert "Terminal=false" in text
    assert "shell=True" not in text
    assert "sh -c" not in text and "bash -c" not in text


@pytest.mark.parametrize("url", ["file:///etc/passwd", "javascript:alert(1)", "https://ok.test/\nBad", "https://"])
def test_only_safe_http_urls_are_accepted(url):
    assert safe_web_url(url) is None
    with pytest.raises(ValueError):
        launcher_contents(Favorite("Bad", url))


def test_create_update_stale_removal_collision_and_permissions(tmp_path):
    manager = DesktopShortcutManager(tmp_path, logging.getLogger("test"))
    unrelated = tmp_path / "notes.desktop"
    unrelated.write_text("unrelated", encoding="utf-8")
    collision = tmp_path / "my-desktop-weather.desktop"
    collision.write_text("unowned", encoding="utf-8")
    stale = tmp_path / "my-desktop-stale.desktop"
    stale.write_text(f"[Desktop Entry]\n{MANAGED_MARKER}\n", encoding="utf-8")

    first = manager.sync([Favorite("Gmail", "https://mail.test"), Favorite("Weather", "https://weather.test")])
    gmail = tmp_path / "my-desktop-gmail.desktop"
    assert first.created == 1 and first.removed == 1 and first.refused == 1
    assert gmail.exists() and not stale.exists()
    assert unrelated.read_text() == "unrelated" and collision.read_text() == "unowned"
    assert stat.S_IMODE(gmail.stat().st_mode) == 0o700

    second = manager.sync([Favorite("Gmail", "https://new.test")])
    assert second.updated == 1
    assert "https://new.test" in gmail.read_text()


def test_remove_all_deletes_owned_launchers_only(tmp_path):
    manager = DesktopShortcutManager(tmp_path, logging.getLogger("test"))
    manager.sync([Favorite("Gmail", "https://mail.test")])
    unrelated = tmp_path / "my-desktop-private.desktop"
    unrelated.write_text("personal", encoding="utf-8")
    ordinary = tmp_path / "photo.jpg"
    ordinary.write_text("photo", encoding="utf-8")
    assert manager.remove_all() == 1
    assert unrelated.exists() and ordinary.exists()
