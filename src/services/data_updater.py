import time
from PySide6.QtCore import QObject, QTimer, Signal
from .redis_client import RedisClient

class DataUpdater(QObject):
    marketUpdated = Signal()
    connectionChanged = Signal(bool)

    def __init__(self, market_model, interval_ms=5000, parent=None):
        super().__init__(parent)
        self._market_model = market_model
        self._client = RedisClient()
        self._timer = QTimer(self)
        self._timer.setInterval(interval_ms)
        self._timer.timeout.connect(self.poll)

    def start(self):
        self.poll()  # initial
        self._timer.start()

    def poll(self):
        ok = self._client.ping()
        self.connectionChanged.emit(ok)
        if not ok:
            return
        market = self._client.get_json("market_data")
        if market:
            self._market_model.update_from_dict(market)
            self.marketUpdated.emit()
