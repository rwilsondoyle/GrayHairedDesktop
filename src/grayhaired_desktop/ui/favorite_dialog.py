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

CONTROL_MINIMUM_HEIGHT = 40
MISSING_NAME_MESSAGE = "Please enter a name for this shortcut."
INVALID_ADDRESS_MESSAGE = (
    "Please enter a complete website address beginning with http:// or https://"
)


class FavoriteDialog(QDialog):
    """Reusable, validated shortcut editor."""

    def __init__(self, favorite: Favorite | None = None, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Edit Shortcut" if favorite else "Add Shortcut")
        self.setMinimumWidth(430)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)
        form = QFormLayout()
        form.setHorizontalSpacing(14)
        form.setVerticalSpacing(12)
        self._name = QLineEdit(favorite.title if favorite else "")
        self._address = QLineEdit(favorite.website_address if favorite else "")
        self._address.setPlaceholderText("https://example.com")
        self._icon = QComboBox()
        self._name.setAccessibleName("Name")
        self._name.setAccessibleDescription("Enter a name for this shortcut.")
        self._address.setAccessibleName("Website Address")
        self._address.setAccessibleDescription(
            "Enter the complete website address for this shortcut."
        )
        self._icon.setAccessibleName("Icon")
        self._icon.setAccessibleDescription("Choose an icon for this shortcut.")
        for control in (self._name, self._address, self._icon):
            control.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
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
        self._save_button = QPushButton("Save")
        self._save_button.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
        self._save_button.setDefault(True)
        buttons.addButton(self._save_button, QDialogButtonBox.ButtonRole.AcceptRole)
        self._cancel_button = buttons.button(QDialogButtonBox.StandardButton.Cancel)
        self._cancel_button.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
        buttons.accepted.connect(self._validate_and_accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        self.setTabOrder(self._name, self._address)
        self.setTabOrder(self._address, self._icon)
        self.setTabOrder(self._icon, self._save_button)
        self.setTabOrder(self._save_button, self._cancel_button)
        self.setTabOrder(self._cancel_button, self._name)

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
                "Check Shortcut Name",
                MISSING_NAME_MESSAGE,
            )
            self._name.setFocus()
            return

        address = self._address.text().strip()
        if not is_valid_home_page_url(address):
            QMessageBox.warning(
                self,
                "Check Website Address",
                INVALID_ADDRESS_MESSAGE,
            )
            self._address.setFocus()
            self._address.selectAll()
            return
        self.accept()
