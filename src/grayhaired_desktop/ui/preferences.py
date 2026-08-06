"""Settings dialog for choosing the desktop website."""

from __future__ import annotations

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QButtonGroup,
    QFrame,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QRadioButton,
    QPushButton,
    QMessageBox,
    QScrollArea,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from grayhaired_desktop.settings import (
    BUILT_IN_WEBSITES,
    UserPreferences,
    find_built_in_website,
    is_valid_home_page_url,
)

INVALID_URL_MESSAGE = (
    "Please enter a complete website address beginning with http:// or https://"
)


class PreferencesDialog(QDialog):
    """Dialog for editing persistent user preferences."""

    def __init__(self, preferences: UserPreferences, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Settings")
        selected_website = find_built_in_website(preferences.home_page_url)
        custom_address = preferences.home_page_url if selected_website is None else ""
        self._home_page_url = QLineEdit(custom_address, self)
        self._home_page_url.setClearButtonEnabled(True)
        self._website_buttons = QButtonGroup(self)
        self._another_website = QRadioButton("Another Website...", self)
        self._website_buttons.addButton(self._another_website)
        self._built_in_buttons: dict[QRadioButton, str] = {}
        for website in BUILT_IN_WEBSITES:
            button = QRadioButton(website.display_name, self)
            self._website_buttons.addButton(button)
            self._built_in_buttons[button] = website.address
            if website == selected_website:
                button.setChecked(True)
        if selected_website is None:
            self._another_website.setChecked(True)
        self._website_buttons.buttonToggled.connect(self._update_address_field)
        self._create_layout()
        self._update_address_field()

    @property
    def preferences(self) -> UserPreferences:
        """Return the preferences currently entered in the dialog."""

        return UserPreferences(home_page_url=self._selected_address())

    def accept(self) -> None:
        """Validate the URL before allowing the dialog to close."""

        if self._another_website.isChecked() and not is_valid_home_page_url(
            self._home_page_url.text()
        ):
            self._show_invalid_url_message()
            return
        super().accept()

    def _create_layout(self) -> None:
        section_title = QLabel("Desktop Website", self)
        section_title.setStyleSheet("font-weight: bold; font-size: 16px;")
        instruction = QLabel(
            "Choose the website to display inside your desktop.", self
        )
        instruction.setWordWrap(True)
        instruction.setSizePolicy(
            QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Minimum
        )
        instruction.setMinimumHeight(instruction.fontMetrics().lineSpacing() * 2)

        separator = QFrame(self)
        separator.setFrameShape(QFrame.Shape.HLine)
        separator.setFrameShadow(QFrame.Shadow.Sunken)

        address_label = QLabel("Website Address", self)
        address_label.setBuddy(self._home_page_url)
        address_help = QLabel("Copy and paste the website address here.", self)
        address_example = QLabel("Example: https://www.google.com", self)

        self._open_button = QPushButton("Preview in Browser", self)
        preview_description = (
            "Preview the selected website in your default browser without saving changes."
        )
        self._open_button.setToolTip(preview_description)
        self._open_button.setStatusTip(preview_description)
        self._open_button.setAccessibleDescription(preview_description)
        self._open_button.clicked.connect(self._open_home_page)

        button_box = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Save
            | QDialogButtonBox.StandardButton.Cancel,
            self,
        )
        button_box.accepted.connect(self.accept)
        button_box.rejected.connect(self.reject)

        action_layout = QHBoxLayout()
        action_layout.setSpacing(8)
        action_layout.addWidget(self._open_button)
        action_layout.addStretch(1)
        action_layout.addWidget(button_box)

        content = QWidget(self)
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 28, 20, 16)
        content_layout.setSpacing(14)
        content_layout.addWidget(section_title)
        content_layout.addSpacing(4)
        content_layout.addWidget(instruction)
        content_layout.addWidget(self._another_website)
        content_layout.addWidget(address_label)
        content_layout.addWidget(self._home_page_url)
        content_layout.addWidget(address_help)
        content_layout.addWidget(address_example)
        content_layout.addWidget(separator)
        for button in self._built_in_buttons:
            content_layout.addWidget(button)

        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QFrame.Shape.NoFrame)
        scroll_area.setWidget(content)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 16)
        layout.setSpacing(12)
        layout.addWidget(scroll_area)
        action_layout.setContentsMargins(20, 0, 20, 0)
        layout.addLayout(action_layout)

        self.setMinimumSize(440, 520)

        self.setTabOrder(self._another_website, self._home_page_url)
        self.setTabOrder(self._home_page_url, next(iter(self._built_in_buttons)))
        self.setTabOrder(list(self._built_in_buttons)[-1], self._open_button)

    def _open_home_page(self) -> None:
        """Open the entered address externally without saving it."""

        address = self._selected_address()
        if self._another_website.isChecked() and not is_valid_home_page_url(
            self._home_page_url.text()
        ):
            self._show_invalid_url_message()
            return
        if not QDesktopServices.openUrl(QUrl(address)):
            QMessageBox.warning(
                self,
                "Could Not Open Website",
                "The selected website could not be opened in your default browser.",
            )

    def _selected_address(self) -> str:
        """Return the address represented by the current radio selection."""

        if self._another_website.isChecked():
            return self._home_page_url.text().strip()
        checked_button = self._website_buttons.checkedButton()
        return self._built_in_buttons[checked_button]

    def _update_address_field(self, *_args: object) -> None:
        """Allow address editing only for the custom website choice."""

        self._home_page_url.setEnabled(self._another_website.isChecked())

    def _show_invalid_url_message(self) -> None:
        """Explain the accepted URL format and return focus to the field."""

        QMessageBox.warning(self, "Check Website Address", INVALID_URL_MESSAGE)
        self._home_page_url.setFocus()
        self._home_page_url.selectAll()
