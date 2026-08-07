"""Add and edit dialog for desktop shortcuts."""

from __future__ import annotations

from PySide6.QtWidgets import (
    QComboBox,
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QVBoxLayout,
)

from grayhaired_desktop.favorites import Favorite
from grayhaired_desktop.settings import is_valid_home_page_url

ICON_CHOICES = (
    ("Generic Website", "★"),
    ("Email", "✉"),
    ("Weather", "☀"),
    ("News", "▤"),
    ("Video", "▶"),
    ("Shopping", "🛒"),
    ("Social", "☺"),
    ("Family", "♥"),
    ("Bank", "$"),
    ("Medical", "+"),
    ("Church", "✝"),
    ("Travel", "✈"),
    ("Music", "♪"),
    ("Photos", "◉"),
    ("Home", "⌂"),
)


class FavoriteDialog(QDialog):
    """Reusable, validated shortcut editor."""

    def __init__(self, favorite: Favorite | None = None, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Edit Shortcut" if favorite else "Add Shortcut")
        self.setMinimumWidth(430)
        layout = QVBoxLayout(self)
        form = QFormLayout()
        self._name = QLineEdit(favorite.title if favorite else "")
        self._address = QLineEdit(favorite.website_address if favorite else "")
        self._address.setPlaceholderText("https://example.com")
        self._icon = QComboBox()
        for name, symbol in ICON_CHOICES:
            self._icon.addItem(f"{name}   {symbol}", symbol)
        if favorite and favorite.icon_placeholder:
            index = self._icon.findData(favorite.icon_placeholder)
            if index >= 0:
                self._icon.setCurrentIndex(index)
        form.addRow("Name", self._name)
        form.addRow("Website Address", self._address)
        form.addRow("Icon", self._icon)
        layout.addLayout(form)
        layout.addWidget(QLabel("Example: https://example.com"))
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Cancel)
        save = QPushButton("Save")
        save.setDefault(True)
        buttons.addButton(save, QDialogButtonBox.ButtonRole.AcceptRole)
        buttons.accepted.connect(self._validate_and_accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    @property
    def favorite(self) -> Favorite:
        return Favorite(
            self._name.text().strip(),
            self._address.text().strip(),
            self._icon.currentData(),
        )

    def _validate_and_accept(self) -> None:
        if not self._name.text().strip():
            QMessageBox.warning(
                self,
                "Name Required",
                "Please enter a name for this shortcut.",
            )
            self._name.setFocus()
            return

        address = self._address.text().strip()
        if not is_valid_home_page_url(address):
            QMessageBox.warning(
                self,
                "Website Address Required",
                "Please enter a complete website address beginning with\n"
                "http:// or https://",
            )
            self._address.setFocus()
            self._address.selectAll()
            return
        self.accept()
