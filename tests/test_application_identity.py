"""Stable compositor identity tests that do not require a running Qt session."""

from pathlib import Path

from grayhaired_desktop import __app_name__
from grayhaired_desktop.config import AppMetadata, SETTINGS_APPLICATION_NAME


def test_application_id_is_stable_reverse_dns_name():
    metadata = AppMetadata()

    assert metadata.application_id == "tech.grayhaired.GrayHairedDesktop"
    reversed_domain = ".".join(reversed(metadata.domain.split(".")))
    assert metadata.application_id.startswith(f"{reversed_domain}.")
    assert metadata.application_id.count(".") >= 2


def test_public_name_changes_without_internal_identity():
    metadata = AppMetadata()

    assert __app_name__ == metadata.name == "My Desktop"
    assert SETTINGS_APPLICATION_NAME == "GrayHaired Desktop"
    assert metadata.application_id == "tech.grayhaired.GrayHairedDesktop"


def test_application_menu_uses_public_name():
    desktop_entry = Path(__file__).parents[1] / "resources/grayhaired-desktop.desktop.in"

    assert "\nName=My Desktop\n" in desktop_entry.read_text(encoding="utf-8")
