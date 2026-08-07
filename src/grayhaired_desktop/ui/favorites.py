"""Compact, wrapping desktop shortcut launcher."""

from __future__ import annotations

from PySide6.QtCore import QPoint, QRect, QSize, Qt
from PySide6.QtWidgets import (
    QDialog, QHBoxLayout, QLayout, QMenu, QMessageBox, QPushButton,
    QSizePolicy, QToolButton, QWidget,
)

from grayhaired_desktop.favorites import load_favorites, save_favorites
from grayhaired_desktop.ui.favorite_dialog import FavoriteDialog


class FlowLayout(QLayout):
    """A small content-sized layout that wraps widgets."""

    def __init__(self, parent=None, spacing: int = 7) -> None:
        super().__init__(parent)
        self._items = []
        self.setContentsMargins(0, 4, 0, 4)
        self.setSpacing(spacing)

    def addItem(self, item) -> None:  # noqa: N802
        self._items.append(item)

    def count(self) -> int:
        return len(self._items)

    def itemAt(self, index):  # noqa: N802
        return self._items[index] if 0 <= index < len(self._items) else None

    def takeAt(self, index):  # noqa: N802
        return self._items.pop(index) if 0 <= index < len(self._items) else None

    def expandingDirections(self):  # noqa: N802
        return Qt.Orientation(0)

    def hasHeightForWidth(self) -> bool:  # noqa: N802
        return True

    def heightForWidth(self, width: int) -> int:  # noqa: N802
        return self._arrange(QRect(0, 0, width, 0), True)

    def setGeometry(self, rect: QRect) -> None:  # noqa: N802
        super().setGeometry(rect)
        self._arrange(rect, False)

    def sizeHint(self) -> QSize:  # noqa: N802
        return self.minimumSize()

    def minimumSize(self) -> QSize:  # noqa: N802
        size = QSize()
        for item in self._items:
            size = size.expandedTo(item.minimumSize())
        margins = self.contentsMargins()
        return size + QSize(margins.left() + margins.right(), margins.top() + margins.bottom())

    def _arrange(self, rect: QRect, test_only: bool) -> int:
        margins = self.contentsMargins()
        x, y = rect.x() + margins.left(), rect.y() + margins.top()
        row_height = 0
        right = rect.right() - margins.right()
        for item in self._items:
            hint = item.sizeHint()
            if x > rect.x() + margins.left() and x + hint.width() > right:
                x = rect.x() + margins.left()
                y += row_height + self.spacing()
                row_height = 0
            if not test_only:
                item.setGeometry(QRect(QPoint(x, y), hint))
            x += hint.width() + self.spacing()
            row_height = max(row_height, hint.height())
        return y + row_height + margins.bottom() - rect.y()


class FavoritesWidget(QWidget):
    """Editable desktop shortcuts without a visible section heading."""

    STYLE = """
        QPushButton, QToolButton { font-size: 14px; min-height: 36px; padding: 0 9px;
          border: 1px solid #8b929a; border-radius: 7px; background: #f6f7f8; color: #202124; }
        QPushButton:hover, QToolButton:hover { background: #e4edf7; border-color: #4778a8; }
        QPushButton:pressed, QToolButton:pressed { background: #cddceb; }
        QPushButton:focus, QToolButton:focus { border: 2px solid #155ea8; }
        QToolButton { padding: 0 7px; }
    """

    def __init__(self, settings, open_external, parent=None) -> None:
        super().__init__(parent)
        self._settings = settings
        self._open_external = open_external
        self._favorites = load_favorites(settings)
        self._flow = FlowLayout(self)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.setStyleSheet(self.STYLE)
        self._refresh()

    def _refresh(self) -> None:
        while self._flow.count():
            item = self._flow.takeAt(0)
            item.widget().deleteLater()
        for index, favorite in enumerate(self._favorites):
            group = QWidget()
            row = QHBoxLayout(group)
            row.setContentsMargins(0, 0, 0, 0)
            row.setSpacing(2)
            shortcut = QPushButton(f"{favorite.icon_placeholder or '★'}  {favorite.title}")
            shortcut.setToolTip(f"Open {favorite.title}")
            shortcut.clicked.connect(
                lambda checked=False, url=favorite.website_address: self._open_external(url)
            )
            menu_button = QToolButton()
            menu_button.setText("⋮")
            menu_button.setToolTip(f"Edit or remove {favorite.title} shortcut")
            menu_button.setAccessibleName(f"Shortcut options for {favorite.title}")
            menu = QMenu(menu_button)
            menu.addAction("Edit Shortcut", lambda checked=False, i=index: self._edit(i))
            menu.addAction("Remove Shortcut", lambda checked=False, i=index: self._remove(i))
            menu_button.setMenu(menu)
            menu_button.setPopupMode(QToolButton.ToolButtonPopupMode.InstantPopup)
            row.addWidget(shortcut)
            row.addWidget(menu_button)
            self._flow.addWidget(group)
        add = QPushButton("+ Add Shortcut")
        add.clicked.connect(self._add)
        self._flow.addWidget(add)
        self.updateGeometry()

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
        box = QMessageBox(QMessageBox.Icon.Question, "Remove Shortcut",
                          f'Remove "{favorite.title}" from your desktop shortcuts?',
                          parent=self)
        remove = box.addButton("Remove", QMessageBox.ButtonRole.DestructiveRole)
        box.addButton("Cancel", QMessageBox.ButtonRole.RejectRole)
        box.exec()
        if box.clickedButton() is remove:
            del self._favorites[index]
            self._save_and_refresh()

    def _save_and_refresh(self) -> None:
        save_favorites(self._settings, self._favorites)
        self._refresh()
