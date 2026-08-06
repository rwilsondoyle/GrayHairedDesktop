"""Preferences dialog for GrayHaired Desktop."""

from __future__ import annotations

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QMessageBox,
    QVBoxLayout,
)

from grayhaired_desktop.settings import (
    DEFAULT_HOME_PAGE_URL,
    UserPreferences,
    is_valid_home_page_url,
)

INVALID_URL_MESSAGE = (
    "Please enter a complete web address beginning with http:// or https://"
)


class PreferencesDialog(QDialog):
    """Dialog for editing persistent user preferences."""

    def __init__(self, preferences: UserPreferences, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Preferences")
        self._home_page_url = QLineEdit(preferences.home_page_url, self)
        self._home_page_url.setPlaceholderText(DEFAULT_HOME_PAGE_URL)
        self._home_page_url.setClearButtonEnabled(True)
        self._create_layout()

    @property
    def preferences(self) -> UserPreferences:
        """Return the preferences currently entered in the dialog."""

        home_page_url = self._home_page_url.text().strip()
        return UserPreferences(home_page_url=home_page_url)

    def accept(self) -> None:
        """Validate the URL before allowing the dialog to close."""

        if not is_valid_home_page_url(self._home_page_url.text()):
            self._show_invalid_url_message()
            return
        super().accept()

    def _create_layout(self) -> None:
        form_layout = QFormLayout()
        form_layout.setHorizontalSpacing(16)
        form_layout.setVerticalSpacing(12)
        form_layout.addRow("Home Page URL:", self._home_page_url)

        help_text = QLabel(
            "The Home Page is the page displayed inside the desktop application. "
            "Links clicked on that page open in your regular web browser.",
            self,
        )
        help_text.setWordWrap(True)

        self._open_button = QPushButton("Open Home Page", self)
        self._open_button.clicked.connect(self._open_home_page)
        self._restore_defaults_button = QPushButton("Restore Default Home Page", self)
        self._restore_defaults_button.clicked.connect(self._restore_default_home_page)

        button_box = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel,
            self,
        )
        button_box.accepted.connect(self.accept)
        button_box.rejected.connect(self.reject)

        action_layout = QHBoxLayout()
        action_layout.setSpacing(8)
        action_layout.addWidget(self._open_button)
        action_layout.addWidget(self._restore_defaults_button)
        action_layout.addStretch(1)
        action_layout.addWidget(button_box)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)
        layout.addWidget(help_text)
        layout.addLayout(form_layout)
        layout.addLayout(action_layout)

        self.setTabOrder(self._home_page_url, self._open_button)
        self.setTabOrder(self._open_button, self._restore_defaults_button)

    def _open_home_page(self) -> None:
        """Open the entered address externally without saving it."""

        address = self._home_page_url.text()
        if not is_valid_home_page_url(address):
            self._show_invalid_url_message()
            return
        if not QDesktopServices.openUrl(QUrl(address)):
            QMessageBox.warning(
                self,
                "Could Not Open Home Page",
                "The Home Page could not be opened in your regular web browser.",
            )

    def _restore_default_home_page(self) -> None:
        """Confirm and place the default address in the editable field."""

        answer = QMessageBox.question(
            self,
            "Restore Default Home Page",
            "Restore the original default Home Page address?",
            QMessageBox.StandardButton.Restore | QMessageBox.StandardButton.Cancel,
            QMessageBox.StandardButton.Cancel,
        )
        if answer != QMessageBox.StandardButton.Restore:
            return
        self._home_page_url.setText(DEFAULT_HOME_PAGE_URL)
        self._home_page_url.setFocus()

    def _show_invalid_url_message(self) -> None:
        """Explain the accepted URL format and return focus to the field."""

        QMessageBox.warning(self, "Check Home Page Address", INVALID_URL_MESSAGE)
        self._home_page_url.setFocus()
        self._home_page_url.selectAll()
