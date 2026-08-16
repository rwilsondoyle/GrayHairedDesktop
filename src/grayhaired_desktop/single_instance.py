"""Single-instance coordination using Qt's user-local IPC support."""

from __future__ import annotations

from enum import Enum, auto

from PySide6.QtCore import QObject, Signal
from PySide6.QtNetwork import QLocalServer, QLocalSocket

ACTIVATION_MESSAGE = b"ACTIVATE\n"
CONNECTION_TIMEOUT_MS = 500


class InstanceRole(Enum):
    """The result of attempting to acquire the application endpoint."""

    PRIMARY = auto()
    SECONDARY = auto()


def server_name(application_id: str) -> str:
    """Return the stable per-user endpoint name for an application identity.

    QLocalServer scopes named endpoints to the current user on supported Unix
    platforms. Keeping the name derived from the compositor identity avoids a
    second, unrelated application identifier.
    """

    return f"{application_id}.single-instance"


class SingleInstanceGuard(QObject):
    """Own the primary endpoint or notify the process that already owns it."""

    activation_requested = Signal()

    def __init__(self, name: str, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.name = name
        self._server = QLocalServer(self)
        self._server.newConnection.connect(self._accept_connections)
        self._connections: dict[QLocalSocket, bytearray] = {}
        self._owns_endpoint = False

    @property
    def owns_endpoint(self) -> bool:
        """Whether this guard successfully established the primary server."""

        return self._owns_endpoint

    def acquire(self) -> InstanceRole:
        """Notify a primary, or safely recover a demonstrably stale endpoint."""

        if self._notify_primary():
            return InstanceRole.SECONDARY

        # Listening before removing anything is important: the normal case has
        # no endpoint, and an active primary must never be unlinked.
        if self._listen():
            return InstanceRole.PRIMARY

        # A primary may have appeared between our connect and listen attempts.
        # Retry before treating connection-refused/not-found state as stale.
        if self._notify_primary():
            return InstanceRole.SECONDARY

        error = self._last_socket_error
        stale_errors = {
            QLocalSocket.LocalSocketError.ConnectionRefusedError,
            QLocalSocket.LocalSocketError.ServerNotFoundError,
        }
        if error not in stale_errors or not QLocalServer.removeServer(self.name):
            raise RuntimeError(
                f"Could not safely acquire local server {self.name!r}: "
                f"{self._server.errorString()}"
            )
        if not self._listen():
            raise RuntimeError(
                f"Could not listen on recovered local server {self.name!r}: "
                f"{self._server.errorString()}"
            )
        return InstanceRole.PRIMARY

    def close(self) -> None:
        """Release only an endpoint established by this guard."""

        if not self._owns_endpoint:
            return
        self._server.close()
        QLocalServer.removeServer(self.name)
        self._owns_endpoint = False

    def _listen(self) -> bool:
        if not self._server.listen(self.name):
            return False
        self._owns_endpoint = True
        return True

    def _notify_primary(self) -> bool:
        socket = QLocalSocket()
        socket.connectToServer(self.name)
        if not socket.waitForConnected(CONNECTION_TIMEOUT_MS):
            self._last_socket_error = socket.error()
            return False
        socket.write(ACTIVATION_MESSAGE)
        socket.flush()
        socket.waitForBytesWritten(CONNECTION_TIMEOUT_MS)
        socket.disconnectFromServer()
        return True

    def _accept_connections(self) -> None:
        while self._server.hasPendingConnections():
            socket = self._server.nextPendingConnection()
            if socket is None:
                continue
            self._connections[socket] = bytearray()
            socket.readyRead.connect(lambda socket=socket: self._read(socket))
            self._read(socket)

    def _read(self, socket: QLocalSocket) -> None:
        buffer = self._connections.get(socket)
        if buffer is None:
            return
        buffer.extend(bytes(socket.readAll()))
        if ACTIVATION_MESSAGE in buffer:
            self.activation_requested.emit()
            self._connections.pop(socket, None)
            socket.disconnectFromServer()
            socket.deleteLater()
