"""Release-facing version and About-dialog consistency checks."""

from pathlib import Path
from types import SimpleNamespace

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)

from grayhaired_desktop import __app_name__, __version__
from grayhaired_desktop.desktop_mode import DesktopModePath
from grayhaired_desktop.ui.mainwindow import MainWindow


def test_packaging_and_runtime_versions_match() -> None:
    """Keep the package source of truth and runtime mirror synchronized."""

    pyproject = Path(__file__).parents[1] / "pyproject.toml"
    packaging_version = next(
        line.split('"', 2)[1]
        for line in pyproject.read_text(encoding="utf-8").splitlines()
        if line.startswith("version = ")
    )

    assert packaging_version == __version__ == "1.0.0"


def test_desktop_menu_uses_public_name_and_stable_launcher() -> None:
    desktop_entry = (
        Path(__file__).parents[1] / "resources/grayhaired-desktop.desktop.in"
    ).read_text(encoding="utf-8")

    assert "Name=My Desktop\n" in desktop_entry
    assert "Exec=@EXEC@\n" in desktop_entry
    pyproject = (Path(__file__).parents[1] / "pyproject.toml").read_text(encoding="utf-8")
    assert 'grayhaired-desktop = "grayhaired_desktop.app:main"' in pyproject


def test_startup_always_requests_safe_windowed_mode() -> None:
    requested = []
    window = type(
        "WindowStub",
        (),
        {
            "_apply_desktop_mode": lambda self, value: requested.append(value)
            or DesktopModePath.WINDOWED
        },
    )()

    assert MainWindow.apply_startup_mode(window) is DesktopModePath.WINDOWED
    assert requested == [False]


def test_about_is_product_focused_without_prerelease_wording(monkeypatch) -> None:
    """About identifies the application without presenting it as a browser."""

    captured: dict[str, str] = {}

    def capture_about(parent, title: str, message: str) -> None:
        captured.update(title=title, message=message)

    monkeypatch.setattr(
        "grayhaired_desktop.ui.mainwindow.QMessageBox.about", capture_about
    )
    window = SimpleNamespace(
        _metadata=SimpleNamespace(name=__app_name__, version=__version__)
    )

    MainWindow._show_about_dialog(window)

    assert __app_name__ == "My Desktop"
    assert captured["title"] == "About My Desktop"
    assert captured["message"].startswith("My Desktop 1.0.0")
    assert "Desktop Website" in captured["message"]
    assert "default browser" in captured["message"]
    assert "Alpha" not in captured["message"]
    assert "Beta" not in captured["message"]
