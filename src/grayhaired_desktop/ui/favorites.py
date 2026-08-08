"""Compact, centered desktop shortcut launcher."""

from __future__ import annotations

from PySide6.QtCore import QPoint, Qt
from PySide6.QtWidgets import (
    QDialog,
    QHBoxLayout,
    QMenu,
    QMessageBox,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from grayhaired_desktop.favorites import Favorite, load_favorites, save_favorites
from grayhaired_desktop.ui.favorite_dialog import FavoriteDialog


class FavoritesWidget(QWidget):
    """Editable desktop shortcuts shown in at most two centered rows."""

    _MAX_BUTTON_WIDTH = 220
    _BUTTON_TEXT_WIDTH = 180
    _BUTTON_MINIMUM_HEIGHT = 42
    _ROW_SPACING = 8

    _SYSTEM_STYLE = """
        QPushButton {
            font-size: 14px;
            min-height: 42px;
            padding: 0 9px;
        }
    """
    _LIGHT_STYLE = """
        QPushButton {
            font-size: 14px;
            min-height: 42px;
            padding: 0 9px;
            border: 1px solid #a5abb2;
            border-radius: 7px;
            background: rgba(248, 249, 250, 235);
            color: #202124;
        }
        QPushButton:hover { background: #e7eef6; border-color: #557da5; }
        QPushButton:pressed { background: #d6e2ee; }
        QPushButton:focus { border: 2px solid #155ea8; }
    """
    _DARK_STYLE = """
        QPushButton {
            font-size: 14px;
            min-height: 42px;
            padding: 0 9px;
            border: 1px solid #666c73;
            border-radius: 7px;
            background: rgba(45, 48, 52, 235);
            color: #f1f3f4;
        }
        QPushButton:hover { background: #3d4f61; border-color: #7aa2c8; }
        QPushButton:pressed { background: #324354; }
        QPushButton:focus { border: 2px solid #8ab4f8; }
    """

    def __init__(
        self,
        settings,
        open_external,
        shortcut_theme: str = "system",
        parent=None,
    ) -> None:
        super().__init__(parent)
        self._settings = settings
        self._open_external = open_external
        self._favorites = load_favorites(settings)
        self._shortcut_theme = "system"
        self._last_layout_width = -1

        self._layout = QVBoxLayout(self)
        self._layout.setContentsMargins(0, 4, 0, 4)
        self._layout.setSpacing(self._ROW_SPACING)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.customContextMenuRequested.connect(self._show_empty_space_menu)

        self.set_theme(shortcut_theme)
        self._rebuild_rows()

    def set_theme(self, theme: str) -> None:
        """Apply the user's shortcut appearance choice."""

        normalized = theme if theme in {"system", "light", "dark"} else "system"
        self._shortcut_theme = normalized
        if normalized == "light":
            self.setStyleSheet(self._LIGHT_STYLE)
        elif normalized == "dark":
            self.setStyleSheet(self._DARK_STYLE)
        else:
            # Leave colors to Qt/Zorin so the buttons follow the computer theme.
            self.setStyleSheet(self._SYSTEM_STYLE)

    def resizeEvent(self, event) -> None:  # noqa: N802 - Qt override name
        """Re-center and repack shortcuts when the available width changes."""

        super().resizeEvent(event)
        if event.size().width() != self._last_layout_width:
            self._rebuild_rows()

    def _rebuild_rows(self) -> None:
        self._last_layout_width = self.width()
        self._clear_rows()

        available_width = max(320, self.contentsRect().width())
        button_specs = [
            (index, self._make_shortcut_button(index, favorite))
            for index, favorite in enumerate(self._favorites)
        ]
        add_button = QPushButton("+ Add Shortcut", self)
        add_button.setMinimumHeight(self._BUTTON_MINIMUM_HEIGHT)
        add_button.setAccessibleName("Add Shortcut")
        add_button.clicked.connect(self._add)

        first_row: list[tuple[int, QPushButton]] = []
        second_row: list[tuple[int, QPushButton]] = []
        overflow: list[tuple[int, QPushButton]] = []
        first_width = 0
        second_width = 0

        for spec in button_specs:
            width = self._item_width(spec[1])
            if self._fits(first_width, width, available_width):
                first_row.append(spec)
                first_width = self._combined_width(first_width, width)
            elif self._fits(second_width, width, available_width):
                second_row.append(spec)
                second_width = self._combined_width(second_width, width)
            else:
                overflow.append(spec)

        add_width = self._item_width(add_button)
        if second_row:
            while second_row and not self._fits(second_width, add_width, available_width):
                moved = second_row.pop()
                moved_width = self._item_width(moved[1])
                second_width = self._remove_width(second_width, moved_width)
                overflow.insert(0, moved)
            second_row.append((-1, add_button))
            second_width = self._combined_width(second_width, add_width)
        elif self._fits(first_width, add_width, available_width):
            first_row.append((-1, add_button))
            first_width = self._combined_width(first_width, add_width)
        else:
            second_row.append((-1, add_button))
            second_width = add_width

        if overflow:
            more_button = QPushButton("More...", self)
            more_button.setMinimumHeight(self._BUTTON_MINIMUM_HEIGHT)
            more_button.setAccessibleName("More Shortcuts")
            more_button.setToolTip("Show additional shortcuts")
            more_width = self._item_width(more_button)
            while second_row and not self._fits(second_width, more_width, available_width):
                if second_row[-1][0] == -1 and len(second_row) > 1:
                    moved = second_row.pop(-2)
                elif second_row[-1][0] != -1:
                    moved = second_row.pop()
                else:
                    break
                moved_width = self._item_width(moved[1])
                second_width = self._remove_width(second_width, moved_width)
                overflow.insert(0, moved)
            more_button.clicked.connect(
                lambda checked=False, button=more_button, items=list(overflow): (
                    self._show_more_menu(button, items)
                )
            )
            second_row.append((-2, more_button))
            for _, hidden_button in overflow:
                hidden_button.hide()

        self._add_centered_row(first_row)
        if second_row:
            self._add_centered_row(second_row)
        self.updateGeometry()

    def _clear_rows(self) -> None:
        while self._layout.count():
            item = self._layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()

    def _add_centered_row(self, specs: list[tuple[int, QPushButton]]) -> None:
        row_widget = QWidget(self)
        row = QHBoxLayout(row_widget)
        row.setContentsMargins(0, 0, 0, 0)
        row.setSpacing(self._ROW_SPACING)
        row.addStretch(1)
        for _, button in specs:
            button.setParent(row_widget)
            row.addWidget(button)
        row.addStretch(1)
        self._layout.addWidget(row_widget)

    def _make_shortcut_button(self, index: int, favorite: Favorite) -> QPushButton:
        display = f"{favorite.icon_placeholder or '★'}  {favorite.title}"
        button = QPushButton(self)
        button.setMinimumHeight(self._BUTTON_MINIMUM_HEIGHT)
        button.setText(
            button.fontMetrics().elidedText(
                display,
                Qt.TextElideMode.ElideRight,
                self._BUTTON_TEXT_WIDTH,
            )
        )
        button.setMaximumWidth(self._MAX_BUTTON_WIDTH)
        button.setAccessibleName(favorite.title)
        button.setToolTip(f"{favorite.title}\nRight-click to edit this shortcut")
        button.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        button.clicked.connect(
            lambda checked=False, url=favorite.website_address: self._open_external(url)
        )
        button.customContextMenuRequested.connect(
            lambda position, i=index, shortcut=button: self._show_menu(
                i, shortcut, position
            )
        )
        return button

    def _show_menu(self, index: int, shortcut: QPushButton, position: QPoint) -> None:
        menu = QMenu(shortcut)
        menu.addAction("Edit Shortcut", lambda: self._edit(index))
        menu.addAction("Remove Shortcut", lambda: self._remove(index))
        menu.exec(shortcut.mapToGlobal(position))

    def _show_more_menu(
        self,
        button: QPushButton,
        items: list[tuple[int, QPushButton]],
    ) -> None:
        menu = QMenu(button)
        for index, _ in items:
            if index < 0:
                continue
            favorite = self._favorites[index]
            submenu = menu.addMenu(
                f"{favorite.icon_placeholder or '★'}  {favorite.title}"
            )
            submenu.addAction(
                "Open",
                lambda checked=False, url=favorite.website_address: (
                    self._open_external(url)
                ),
            )
            submenu.addAction(
                "Edit Shortcut",
                lambda checked=False, i=index: self._edit(i),
            )
            submenu.addAction(
                "Remove Shortcut",
                lambda checked=False, i=index: self._remove(i),
            )
        menu.exec(button.mapToGlobal(QPoint(0, button.height())))

    def _show_empty_space_menu(self, position: QPoint) -> None:
        child = self.childAt(position)
        if isinstance(child, QPushButton):
            return
        menu = QMenu(self)
        menu.addAction("Add Shortcut", self._add)
        menu.exec(self.mapToGlobal(position))

    def _add(self) -> None:
        dialog = FavoriteDialog(parent=self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self._favorites.append(dialog.favorite)
            self._save_and_refresh()

    def _edit(self, index: int) -> None:
        dialog = FavoriteDialog(self._favorites[index], self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self._favorites[index] = dialog.favorite
            self._save_and_refresh()

    def _remove(self, index: int) -> None:
        favorite = self._favorites[index]
        box = QMessageBox(
            QMessageBox.Icon.Question,
            "Remove Shortcut",
            f'Remove "{favorite.title}" from your desktop shortcuts?',
            parent=self,
        )
        remove = box.addButton("Remove", QMessageBox.ButtonRole.DestructiveRole)
        box.addButton("Cancel", QMessageBox.ButtonRole.RejectRole)
        box.exec()
        if box.clickedButton() is remove:
            del self._favorites[index]
            self._save_and_refresh()

    def _save_and_refresh(self) -> None:
        save_favorites(self._settings, self._favorites)
        self._rebuild_rows()

    @classmethod
    def _fits(cls, current: int, item: int, available: int) -> bool:
        needed = item if current == 0 else current + cls._ROW_SPACING + item
        return needed <= available

    @classmethod
    def _combined_width(cls, current: int, item: int) -> int:
        return item if current == 0 else current + cls._ROW_SPACING + item

    @classmethod
    def _remove_width(cls, current: int, item: int) -> int:
        if current <= item:
            return 0
        return current - item - cls._ROW_SPACING

    def _item_width(self, button: QPushButton) -> int:
        return min(button.sizeHint().width(), self._MAX_BUTTON_WIDTH)
