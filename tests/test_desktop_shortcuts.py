"""Desktop launcher tests use temporary Desktop directories exclusively."""

from __future__ import annotations

import logging
import stat
import subprocess

import pytest

from grayhaired_desktop.desktop_shortcuts import (
    MANAGED_MARKER,
    POSITION_ATTRIBUTE,
    DesktopShortcutManager,
    DesktopShortcutPlacementManager,
    format_icon_position,
    launcher_contents,
    launcher_slug,
    parse_icon_position,
    preset_positions,
    resolve_desktop_directory,
    safe_web_url,
)
from grayhaired_desktop.favorites import Favorite


def completed(stdout: str) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess([], 0, stdout, "")


def test_xdg_desktop_resolution_creates_valid_directory(tmp_path):
    target = tmp_path / "My Desktop"
    resolved = resolve_desktop_directory(
        tmp_path, runner=lambda *a, **k: completed(f"{target}\n")
    )
    assert resolved == target
    assert resolved.is_dir()


@pytest.mark.parametrize("output", ["", "/tmp/outside", ".", "relative/Desktop"])
def test_resolution_falls_back_and_remains_inside_home(tmp_path, output):
    resolved = resolve_desktop_directory(
        tmp_path, runner=lambda *a, **k: completed(output)
    )
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
    text = launcher_contents(
        Favorite("Gmail\nUnsafe", "https://example.com/a?q=1"),
        "/home/me/grayhaired-desktop",
    )
    assert "Type=Application" in text
    assert "Name=Gmail Unsafe" in text
    assert MANAGED_MARKER in text
    assert (
        'Exec="/home/me/grayhaired-desktop" --open-url "https://example.com/a?q=1"'
        in text
    )
    assert "Terminal=false" in text
    assert "shell=True" not in text
    assert "sh -c" not in text and "bash -c" not in text


@pytest.mark.parametrize(
    "url",
    ["file:///etc/passwd", "javascript:alert(1)", "https://ok.test/\nBad", "https://"],
)
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

    first = manager.sync(
        [
            Favorite("Gmail", "https://mail.test"),
            Favorite("Weather", "https://weather.test"),
        ]
    )
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


def test_position_parser_and_formatter_are_strict():
    assert parse_icon_position("632,2") == (632, 2)
    assert parse_icon_position(" 800, 300 ") == (800, 300)
    assert parse_icon_position("-1,2") is None
    assert parse_icon_position("not-a-position") is None
    assert format_icon_position((1157, 614)) == "1157,614"
    with pytest.raises(ValueError):
        format_icon_position((-1, 2))


def test_preset_positions_stay_above_panel_and_away_from_right_edge():
    positions = preset_positions(7, 1366, 768)
    assert len(positions) == 7
    assert len(set(positions)) == 7
    assert all(0 <= x < 1186 for x, _ in positions)
    assert all(0 <= y <= int(768 * 0.55) for _, y in positions)


class FakeGioRunner:
    def __init__(self, positions: dict[str, str], fail_set_for: str | None = None):
        self.positions = positions
        self.fail_set_for = fail_set_for
        self.calls: list[list[str]] = []

    def __call__(self, args, **kwargs):
        self.calls.append(list(args))
        name = args[-1] if args[1] == "info" else args[2]
        filename = name.rsplit("/", 1)[-1]
        if args[1] == "info":
            value = self.positions.get(filename)
            stdout = "" if value is None else f"  {POSITION_ATTRIBUTE}: {value}\n"
            return completed(stdout)
        if args[1] == "set":
            if filename == self.fail_set_for:
                raise subprocess.CalledProcessError(1, args)
            assert args[3] == POSITION_ATTRIBUTE
            self.positions[filename] = args[4]
            return completed("")
        raise AssertionError(args)


def make_managed_launcher(path):
    contents = f"[Desktop Entry]\nName=Test\n{MANAGED_MARKER}\n"
    path.write_text(contents, encoding="utf-8")
    return contents


def test_capture_arrange_and_restore_only_managed_launchers(tmp_path):
    gmail = tmp_path / "my-desktop-gmail.desktop"
    weather = tmp_path / "my-desktop-weather.desktop"
    unrelated = tmp_path / "notes.desktop"
    gmail_contents = make_managed_launcher(gmail)
    weather_contents = make_managed_launcher(weather)
    unrelated.write_text("unrelated", encoding="utf-8")
    runner = FakeGioRunner(
        {
            gmail.name: "632,2",
            weather.name: "2,308",
            unrelated.name: "400,400",
        }
    )
    refreshed: list[str] = []
    manager = DesktopShortcutPlacementManager(
        tmp_path,
        logging.getLogger("test"),
        runner=runner,
        refresher=lambda path: refreshed.append(path.name),
    )

    captured = manager.capture_positions()
    assert captured == {gmail.name: "632,2", weather.name: "2,308"}

    arranged = manager.arrange(1366, 768)
    assert arranged.moved == 2 and arranged.failed == 0
    assert refreshed == [gmail.name, weather.name]
    assert gmail.read_text(encoding="utf-8") == gmail_contents
    assert weather.read_text(encoding="utf-8") == weather_contents
    assert unrelated.read_text(encoding="utf-8") == "unrelated"
    assert all("metadata::trusted" not in " ".join(call) for call in runner.calls)

    restored = manager.restore(captured)
    assert restored.moved == 2 and restored.failed == 0
    assert runner.positions[gmail.name] == "632,2"
    assert runner.positions[weather.name] == "2,308"


def test_failed_position_write_does_not_refresh_or_touch_unrelated_files(tmp_path):
    gmail = tmp_path / "my-desktop-gmail.desktop"
    unrelated = tmp_path / "my-desktop-private.desktop"
    make_managed_launcher(gmail)
    unrelated.write_text("personal", encoding="utf-8")
    runner = FakeGioRunner({gmail.name: "2,2"}, fail_set_for=gmail.name)
    refreshed: list[str] = []
    manager = DesktopShortcutPlacementManager(
        tmp_path,
        logging.getLogger("test"),
        runner=runner,
        refresher=lambda path: refreshed.append(path.name),
    )

    result = manager.arrange(1366, 768)
    assert result.moved == 0 and result.failed == 1
    assert refreshed == []
    assert unrelated.read_text(encoding="utf-8") == "personal"


def test_restore_skips_missing_invalid_or_unmanaged_entries(tmp_path):
    gmail = tmp_path / "my-desktop-gmail.desktop"
    unowned = tmp_path / "my-desktop-private.desktop"
    make_managed_launcher(gmail)
    unowned.write_text("personal", encoding="utf-8")
    runner = FakeGioRunner({gmail.name: "10,20"})
    manager = DesktopShortcutPlacementManager(
        tmp_path,
        logging.getLogger("test"),
        runner=runner,
        refresher=lambda path: None,
    )

    result = manager.restore(
        {
            gmail.name: "100,200",
            unowned.name: "300,400",
            "missing.desktop": "500,600",
            "bad.desktop": "broken",
        }
    )
    assert result.moved == 1
    assert result.skipped == 3
    assert runner.positions[gmail.name] == "100,200"
