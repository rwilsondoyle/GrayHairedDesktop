"""Non-GUI tests for best-effort application logging."""

from __future__ import annotations

import io
import logging
import tempfile
import unittest
from logging.handlers import RotatingFileHandler
from pathlib import Path
from unittest.mock import patch

from grayhaired_desktop.logger import configure_logging


class ConfigureLoggingTests(unittest.TestCase):
    """Verify persistent logging succeeds or degrades safely to stdout."""

    def setUp(self) -> None:
        self.logger = logging.getLogger("grayhaired_desktop")
        self._remove_handlers()

    def tearDown(self) -> None:
        self._remove_handlers()

    def _remove_handlers(self) -> None:
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)
            handler.close()

    def test_writable_log_path_creates_rotating_log(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state" / "grayhaired-desktop.log"
            output = io.StringIO()
            with patch("grayhaired_desktop.logger.log_file_path", return_value=path):
                with patch("sys.stdout", output):
                    logger = configure_logging()
                    configure_logging()
                    logger.info("writable logging test")

            rotating_handlers = [
                handler
                for handler in logger.handlers
                if isinstance(handler, RotatingFileHandler)
            ]
            self.assertEqual(len(rotating_handlers), 1)
            self.assertEqual(rotating_handlers[0].maxBytes, 1024 * 1024)
            self.assertEqual(rotating_handlers[0].backupCount, 3)
            self.assertEqual(rotating_handlers[0].encoding, "utf-8")
            self.assertIn("writable logging test", path.read_text(encoding="utf-8"))
            self.assertIn("writable logging test", output.getvalue())

    def test_unwritable_log_path_keeps_stdout_logging(self) -> None:
        path = Path("/unused/grayhaired-desktop.log")
        output = io.StringIO()
        with patch("grayhaired_desktop.logger.log_file_path", return_value=path):
            with patch.object(
                Path,
                "mkdir",
                side_effect=OSError("simulated read-only state directory"),
            ):
                with patch("sys.stdout", output):
                    logger = configure_logging()
                    configure_logging()
                    logger.info("stdout remains available")

        self.assertFalse(
            any(isinstance(handler, RotatingFileHandler) for handler in logger.handlers)
        )
        self.assertEqual(
            sum(
                bool(getattr(handler, "_graydesk_stdout", False))
                for handler in logger.handlers
            ),
            1,
        )
        self.assertIn("Persistent log file could not be enabled", output.getvalue())
        self.assertIn("simulated read-only state directory", output.getvalue())
        self.assertIn("stdout remains available", output.getvalue())


if __name__ == "__main__":
    unittest.main()
