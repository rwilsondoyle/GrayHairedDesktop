"""Menu-bar construction for the main window."""

from __future__ import annotations

from collections.abc import Callable

from PySide6.QtGui import QAction, QCursor
from PySide6.QtWidgets import QMenuBar, QToolTip, QWidget

from grayhaired_desktop.ui.actions import ApplicationActions
from grayhaired_desktop.ui.tooltips import ToolTipMenu


def _show_action_tooltip(action: QAction, parent: QWidget) -> None:
    """Show a menu action's tooltip consistently across desktop environments."""

    if tooltip := action.toolTip():
        QToolTip.showText(QCursor.pos(), tooltip, parent)


def create_menus(
    menu_bar: QMenuBar,
    actions: ApplicationActions,
    hide_controls: Callable[[], object],
) -> QAction:
    """Populate ``menu_bar`` and return its top-level Done action."""

    file_menu = ToolTipMenu("File", menu_bar)
    menu_bar.addMenu(file_menu)
    file_menu.addAction(actions.exit)

    view_menu = ToolTipMenu("View", menu_bar)
    menu_bar.addMenu(view_menu)
    view_menu.addAction(actions.home)
    view_menu.addAction(actions.reload)

    settings_menu = ToolTipMenu("Settings", menu_bar)
    menu_bar.addMenu(settings_menu)
    settings_menu.addAction(actions.desktop_website)

    help_menu = ToolTipMenu("Help", menu_bar)
    menu_bar.addMenu(help_menu)
    help_menu.addAction(actions.open_log_folder)
    help_menu.addAction(actions.about)

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
    menu_bar.hovered.connect(
        lambda action: (
            _show_action_tooltip(action, menu_bar)
            if action is done_action
            else None
        )
    )
    return done_action
