"""Shared pytest fixtures."""

import pytest


@pytest.fixture(scope="session")
def qt_app():
    """Keep one QApplication alive for the complete GUI test session."""

    widgets = pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
    app = widgets.QApplication.instance() or widgets.QApplication([])
    yield app
