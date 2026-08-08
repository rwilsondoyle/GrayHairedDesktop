"""Menu-bar construction for the main window."""

from __future__ import annotations

from collections.abc import Callable

from PySide6.QtGui import QAction
from PySide6.QtWidgets import QMenu, QMenuBar

from grayhaired_desktop.ui.actions import ApplicationActions
from grayhaired_desktop.ui.tooltips import HelpBubble, MenuHelpController

MENU_BAR_STYLE = "QMenuBar::item { padding: 5px 10px; }"
MENU_STYLE = "QMenu { padding: 4px 0; } QMenu::item { padding: 7px 28px 7px 24px; }"


def create_menus(
    menu_bar: QMenuBar,
    actions: ApplicationActions,
    hide_controls: Callable[[], object],
) -> QAction:
    """Populate ``menu_bar`` and return its top-level Done action."""

    help_bubble = HelpBubble(menu_bar)
    menu_help_controllers = []
    # Add hit area only; colors and other visual details remain native to Qt/Zorin.
    menu_bar.setStyleSheet(MENU_BAR_STYLE)

    file_menu = QMenu("File", menu_bar)
    menu_bar.addMenu(file_menu)
    file_menu.addAction(actions.exit)

    view_menu = QMenu("View", menu_bar)
    menu_bar.addMenu(view_menu)
    view_menu.addAction(actions.home)
    view_menu.addAction(actions.reload)

    settings_menu = QMenu("Settings", menu_bar)
    menu_bar.addMenu(settings_menu)
    settings_menu.addAction(actions.desktop_website)

    help_menu = QMenu("Help", menu_bar)
    menu_bar.addMenu(help_menu)
    help_menu.addAction(actions.open_log_folder)
    help_menu.addAction(actions.about)

    for menu in (file_menu, view_menu, settings_menu, help_menu):
        menu.setStyleSheet(MENU_STYLE)
        menu_help_controllers.append(MenuHelpController(menu, help_bubble))
    # Keep explicit Python references in addition to Qt parent ownership.
    menu_bar._menu_help_bubble = help_bubble
    menu_bar._menu_help_controllers = menu_help_controllers

    done_action = QAction("Done", menu_bar)
    done_action.setToolTip("Return to Desktop Website")
    done_action.setStatusTip("Return to Desktop Website")
    done_action.setWhatsThis("Return to Desktop Website")
    # QAction accessibility derives its name from its visible text. Keep explicit
    # properties as metadata for accessibility bridges that inspect QObject data.
    done_action.setProperty("accessibleName", "Done")
    done_action.setProperty(
        "accessibleDescription", "Return to Desktop Website"
    )
    done_action.triggered.connect(hide_controls)
    menu_bar.addAction(done_action)
    done_help_controller = MenuHelpController(
        menu_bar, help_bubble, actions={done_action}
    )
    menu_help_controllers.append(done_help_controller)
    return done_action
