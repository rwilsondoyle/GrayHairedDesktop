"""Settings dialog for choosing the desktop website."""

from __future__ import annotations

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import (
    QComboBox,
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
PREVIEW_DESCRIPTION = (
    "Open the selected website in your default browser without saving changes."
)
OPEN_WEBSITE_FAILURE_MESSAGE = (
    "The selected website could not be opened in your default browser. Check that "
    "your computer has a working default browser and try again."
)

CONTROL_MINIMUM_HEIGHT = 40
RADIO_MINIMUM_HEIGHT = 38


class PreferencesDialog(QDialog):
    """Dialog for editing persistent user preferences."""

    def __init__(self, preferences: UserPreferences, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Settings")
        selected_website = find_built_in_website(preferences.home_page_url)
        custom_address = preferences.home_page_url if selected_website is None else ""
        self._home_page_url = QLineEdit(custom_address, self)
        self._home_page_url.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
        self._home_page_url.setClearButtonEnabled(True)
        self._home_page_url.setAccessibleName("Website Address")
        self._home_page_url.setAccessibleDescription(
            "Enter the complete address for the Desktop Website."
        )
        self._website_buttons = QButtonGroup(self)
        self._another_website = QRadioButton("Another Website...", self)
        self._another_website.setMinimumHeight(RADIO_MINIMUM_HEIGHT)
        self._website_buttons.addButton(self._another_website)
        self._built_in_buttons: dict[QRadioButton, str] = {}
        for website in BUILT_IN_WEBSITES:
            button = QRadioButton(website.display_name, self)
            button.setMinimumHeight(RADIO_MINIMUM_HEIGHT)
            self._website_buttons.addButton(button)
            self._built_in_buttons[button] = website.address
            if website == selected_website:
                button.setChecked(True)
        if selected_website is None:
            self._another_website.setChecked(True)
        self._website_buttons.buttonToggled.connect(self._update_address_field)

        self._shortcut_theme = QComboBox(self)
        self._shortcut_theme.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
        self._shortcut_theme.addItem("Match Computer", "system")
        self._shortcut_theme.addItem("Light", "light")
        self._shortcut_theme.addItem("Dark", "dark")
        self._shortcut_theme.setAccessibleName("Shortcut Theme")
        self._shortcut_theme.setAccessibleDescription(
            "Choose how desktop shortcuts look."
        )
        theme_index = self._shortcut_theme.findData(preferences.shortcut_theme)
        self._shortcut_theme.setCurrentIndex(max(theme_index, 0))

        self._create_layout()
        self._update_address_field()

    @property
    def preferences(self) -> UserPreferences:
        """Return the preferences currently entered in the dialog."""

        return UserPreferences(
            home_page_url=self._selected_address(),
            shortcut_theme=str(self._shortcut_theme.currentData()),
        )

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
        instruction = QLabel("Choose the website to display on your desktop.", self)
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

        appearance_separator = QFrame(self)
        appearance_separator.setFrameShape(QFrame.Shape.HLine)
        appearance_separator.setFrameShadow(QFrame.Shadow.Sunken)
        appearance_title = QLabel("Shortcut Appearance", self)
        appearance_title.setStyleSheet("font-weight: bold; font-size: 16px;")
        appearance_help = QLabel(
            "Match Computer uses your computer's light or dark appearance. "
            "Choose Light or Dark to use a different appearance.",
            self,
        )
        appearance_help.setWordWrap(True)
        appearance_label = QLabel("Shortcut Theme", self)
        appearance_label.setBuddy(self._shortcut_theme)

        self._open_button = QPushButton("Preview in Browser", self)
        self._open_button.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)
        self._open_button.setAccessibleName("Preview in Browser")
        self._open_button.setToolTip(PREVIEW_DESCRIPTION)
        self._open_button.setStatusTip(PREVIEW_DESCRIPTION)
        self._open_button.setAccessibleDescription(PREVIEW_DESCRIPTION)
        self._open_button.clicked.connect(self._open_home_page)

        button_box = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Save
            | QDialogButtonBox.StandardButton.Cancel,
            self,
        )
        button_box.accepted.connect(self.accept)
        button_box.rejected.connect(self.reject)
        for button in button_box.buttons():
            button.setMinimumHeight(CONTROL_MINIMUM_HEIGHT)

        action_layout = QHBoxLayout()
        action_layout.setSpacing(10)
        action_layout.addWidget(self._open_button)
        action_layout.addStretch(1)
        action_layout.addWidget(button_box)

        content = QWidget(self)
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 28, 20, 16)
        content_layout.setSpacing(16)
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
        content_layout.addWidget(appearance_separator)
        content_layout.addWidget(appearance_title)
        content_layout.addWidget(appearance_help)
        content_layout.addWidget(appearance_label)
        content_layout.addWidget(self._shortcut_theme)

        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QFrame.Shape.NoFrame)
        scroll_area.setWidget(content)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 16)
        layout.setSpacing(14)
        layout.addWidget(scroll_area)
        action_layout.setContentsMargins(20, 0, 20, 0)
        layout.addLayout(action_layout)

        self.setMinimumSize(440, 520)

        self.setTabOrder(self._another_website, self._home_page_url)
        self.setTabOrder(self._home_page_url, next(iter(self._built_in_buttons)))
        self.setTabOrder(list(self._built_in_buttons)[-1], self._shortcut_theme)
        self.setTabOrder(self._shortcut_theme, self._open_button)

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
                OPEN_WEBSITE_FAILURE_MESSAGE,
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
