"""Menu-bar construction for the main window."""

from __future__ import annotations

from PySide6.QtWidgets import QMenuBar

from grayhaired_desktop.ui.actions import ApplicationActions


def create_menus(menu_bar: QMenuBar, actions: ApplicationActions) -> None:
    """Populate ``menu_bar`` with the application's existing menus."""

    file_menu = menu_bar.addMenu("File")
    file_menu.addAction(actions.exit)

    view_menu = menu_bar.addMenu("View")
    view_menu.setToolTipsVisible(True)
    view_menu.addAction(actions.home)
    view_menu.addAction(actions.reload)

    menu_bar.addAction(actions.preferences)

    help_menu = menu_bar.addMenu("Help")
    help_menu.addAction(actions.open_log_folder)
    help_menu.addAction(actions.about)
