"""Preferences dialog for GrayHaired Desktop."""

from __future__ import annotations

from PySide6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QHBoxLayout,
    QLineEdit,
    QPushButton,
    QVBoxLayout,
)

from grayhaired_desktop.settings import DEFAULT_HOME_PAGE_URL, UserPreferences


class PreferencesDialog(QDialog):
    """Dialog for editing persistent user preferences."""

    def __init__(self, preferences: UserPreferences, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Preferences")
        self._home_page_url = QLineEdit(preferences.home_page_url, self)
        self._home_page_url.setPlaceholderText(DEFAULT_HOME_PAGE_URL)
        self._create_layout()

    @property
    def preferences(self) -> UserPreferences:
        """Return the preferences currently entered in the dialog."""

        home_page_url = self._home_page_url.text().strip() or DEFAULT_HOME_PAGE_URL
        return UserPreferences(home_page_url=home_page_url)

    def _create_layout(self) -> None:
        form_layout = QFormLayout()
        form_layout.addRow("Home Page URL", self._home_page_url)

        self._restore_defaults_button = QPushButton("Restore Defaults", self)
        self._restore_defaults_button.clicked.connect(self._restore_defaults)

        button_box = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel,
            self,
        )
        button_box.accepted.connect(self.accept)
        button_box.rejected.connect(self.reject)

        action_layout = QHBoxLayout()
        action_layout.addWidget(self._restore_defaults_button)
        action_layout.addStretch(1)
        action_layout.addWidget(button_box)

        layout = QVBoxLayout(self)
        layout.addLayout(form_layout)
        layout.addLayout(action_layout)

    def _restore_defaults(self) -> None:
        self._home_page_url.setText(DEFAULT_HOME_PAGE_URL)
