"""Responsive desktop Favorites panel."""

from __future__ import annotations

from collections.abc import Callable, Sequence

from PySide6.QtCore import QEvent, Qt
from PySide6.QtWidgets import (
    QGridLayout,
    QGroupBox,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from grayhaired_desktop.favorites import Favorite


class FavoritesPanel(QGroupBox):
    """Display favorites as compact tiles that reflow with the available width."""

    _MINIMUM_TILE_WIDTH = 112

    def __init__(
        self,
        favorites: Sequence[Favorite],
        selected: Callable[[], None],
        add_selected: Callable[[], None],
        parent: QWidget | None = None,
    ) -> None:
        super().__init__("Favorites", parent)
        self._column_count = 0
        self._row_count = 0
        self._tiles: list[QPushButton] = []
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)

        panel_layout = QVBoxLayout(self)
        panel_layout.setContentsMargins(10, 14, 10, 10)
        self._grid_container = QWidget(self)
        self._grid = QGridLayout(self._grid_container)
        self._grid.setContentsMargins(0, 0, 0, 0)
        self._grid.setHorizontalSpacing(8)
        self._grid.setVerticalSpacing(8)
        panel_layout.addWidget(self._grid_container)

        for favorite in favorites:
            label = "  ".join(
                part for part in (favorite.icon_placeholder, favorite.title) if part
            )
            tile = QPushButton(label, self._grid_container)
            tile.setAccessibleName(favorite.title)
            tile.setCursor(Qt.CursorShape.PointingHandCursor)
            tile.setMinimumHeight(44)
            tile.setSizePolicy(
                QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed
            )
            tile.setProperty("favoriteTile", True)
            if favorite.title == "Add Favorite":
                tile.clicked.connect(add_selected)
                tile.setProperty("addFavoriteTile", True)
            else:
                tile.clicked.connect(selected)
            self._tiles.append(tile)

        self.setStyleSheet(
            """
            QPushButton[favoriteTile="true"] {
                background-color: palette(button);
                border: 1px solid palette(mid);
                border-radius: 12px;
                font-size: 15px;
                font-weight: 600;
                padding: 6px 10px;
            }
            QPushButton[favoriteTile="true"]:hover {
                border: 2px solid palette(highlight);
            }
            QPushButton[favoriteTile="true"]:focus {
                border: 2px solid palette(highlight);
            }
            QPushButton[favoriteTile="true"]:pressed {
                background-color: palette(midlight);
            }
            QPushButton[addFavoriteTile="true"] {
                border-style: dashed;
            }
            """
        )
        self._reflow_tiles()

    def event(self, event: QEvent) -> bool:
        """Reflow tiles after the panel receives its new size."""

        result = super().event(event)
        if event.type() == QEvent.Type.Resize:
            self._reflow_tiles()
        return result

    def _reflow_tiles(self) -> None:
        if not self._tiles:
            return

        spacing = self._grid.horizontalSpacing()
        available_width = max(1, self._grid_container.width())
        column_count = max(
            1, (available_width + spacing) // (self._MINIMUM_TILE_WIDTH + spacing)
        )
        column_count = min(column_count, len(self._tiles))
        if column_count == self._column_count:
            return

        previous_column_count = self._column_count
        self._column_count = column_count
        for index, tile in enumerate(self._tiles):
            self._grid.addWidget(tile, index // column_count, index % column_count)

        for column in range(previous_column_count):
            self._grid.setColumnStretch(column, 0)
        for column in range(column_count):
            self._grid.setColumnStretch(column, 1)
        for row in range(self._row_count):
            self._grid.setRowStretch(row, 0)

        self._row_count = (len(self._tiles) + column_count - 1) // column_count
        for row in range(self._row_count):
            self._grid.setRowStretch(row, 1)
