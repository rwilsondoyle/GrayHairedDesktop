"""Stable compositor identity tests that do not require a running Qt session."""

from grayhaired_desktop.config import AppMetadata


def test_application_id_is_stable_reverse_dns_name():
    metadata = AppMetadata()

    assert metadata.application_id == "tech.grayhaired.GrayHairedDesktop"
    reversed_domain = ".".join(reversed(metadata.domain.split(".")))
    assert metadata.application_id.startswith(f"{reversed_domain}.")
    assert metadata.application_id.count(".") >= 2
