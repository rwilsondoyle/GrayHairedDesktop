"""Release-facing version and About-dialog consistency checks."""

from pathlib import Path
from types import SimpleNamespace

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)

from grayhaired_desktop import __app_name__, __version__
from grayhaired_desktop.ui.mainwindow import MainWindow


def test_packaging_and_runtime_versions_match() -> None:
    """Keep the package source of truth and runtime mirror synchronized."""

    pyproject = Path(__file__).parents[1] / "pyproject.toml"
    packaging_version = next(
        line.split('"', 2)[1]
        for line in pyproject.read_text(encoding="utf-8").splitlines()
        if line.startswith("version = ")
    )

    assert packaging_version == __version__ == "0.9.0"


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

    assert captured["title"] == "About GrayHaired Desktop"
    assert captured["message"].startswith("GrayHaired Desktop 0.9.0")
    assert "Desktop Website" in captured["message"]
    assert "default browser" in captured["message"]
    assert "Alpha" not in captured["message"]
    assert "Beta" not in captured["message"]
