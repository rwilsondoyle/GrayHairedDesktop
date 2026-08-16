"""Tests for Qt local-IPC single-instance coordination."""

from __future__ import annotations

import os
import subprocess
import sys
import time
import uuid

import pytest

from grayhaired_desktop.single_instance import (
    InstanceRole,
    SingleInstanceGuard,
    server_name,
)


def unique_name() -> str:
    return f"grayhaired-desktop-test-{uuid.uuid4().hex}"


@pytest.fixture(scope="module")
def core_app():
    qt_core = pytest.importorskip("PySide6.QtCore", exc_type=ImportError)
    app = qt_core.QCoreApplication.instance() or qt_core.QCoreApplication([])
    return app


def process_until(qt_app, predicate, timeout: float = 2.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        qt_app.processEvents()
        if predicate():
            return True
        time.sleep(0.01)
    return predicate()


def test_server_name_uses_stable_application_identity():
    assert server_name("tech.grayhaired.GrayHairedDesktop") == (
        "tech.grayhaired.GrayHairedDesktop.single-instance"
    )


def test_primary_establishes_server_and_receives_secondary_activation(core_app):
    primary = SingleInstanceGuard(unique_name())
    secondary = SingleInstanceGuard(primary.name)
    activations: list[bool] = []
    primary.activation_requested.connect(lambda: activations.append(True))

    try:
        assert primary.acquire() is InstanceRole.PRIMARY
        assert primary.owns_endpoint
        assert secondary.acquire() is InstanceRole.SECONDARY
        assert not secondary.owns_endpoint
        assert process_until(core_app, lambda: activations == [True])
    finally:
        secondary.close()
        primary.close()


def test_secondary_cleanup_does_not_disrupt_active_primary(core_app):
    primary = SingleInstanceGuard(unique_name())
    secondary = SingleInstanceGuard(primary.name)
    later_secondary = SingleInstanceGuard(primary.name)

    try:
        assert primary.acquire() is InstanceRole.PRIMARY
        assert secondary.acquire() is InstanceRole.SECONDARY
        secondary.close()
        assert later_secondary.acquire() is InstanceRole.SECONDARY
        assert primary.owns_endpoint
    finally:
        later_secondary.close()
        primary.close()


def test_recovers_endpoint_left_by_crashed_process(core_app):
    name = unique_name()
    code = """
import os
from PySide6.QtCore import QCoreApplication
from grayhaired_desktop.single_instance import InstanceRole, SingleInstanceGuard

app = QCoreApplication([])
guard = SingleInstanceGuard(os.environ["TEST_SERVER_NAME"])
assert guard.acquire() is InstanceRole.PRIMARY
os._exit(0)
"""
    environment = os.environ.copy()
    environment["TEST_SERVER_NAME"] = name
    environment["PYTHONPATH"] = "src"
    subprocess.run([sys.executable, "-c", code], check=True, env=environment)

    recovered = SingleInstanceGuard(name)
    try:
        assert recovered.acquire() is InstanceRole.PRIMARY
        assert recovered.owns_endpoint
    finally:
        recovered.close()
