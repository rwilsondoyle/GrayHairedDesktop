"""Stable compositor identity tests that do not require a running Qt session."""

from grayhaired_desktop.config import (
    AppMetadata,
    QSETTINGS_APPLICATION_NAME,
    create_settings,
)


def test_application_id_is_stable_reverse_dns_name():
    metadata = AppMetadata()

    assert metadata.application_id == "tech.grayhaired.GrayHairedDesktop"
    reversed_domain = ".".join(reversed(metadata.domain.split(".")))
    assert metadata.application_id.startswith(f"{reversed_domain}.")
    assert metadata.application_id.count(".") >= 2


def test_public_rename_preserves_qsettings_compatibility_identity(tmp_path, monkeypatch):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path))

    metadata = AppMetadata()
    settings = create_settings(metadata)

    assert metadata.name == "My Desktop"
    assert QSETTINGS_APPLICATION_NAME == "GrayHaired Desktop"
    assert settings.applicationName() == "GrayHaired Desktop"
