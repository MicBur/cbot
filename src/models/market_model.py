from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, QByteArray
from PySide6.QtCore import Signal

class MarketRoles:
    SYMBOL = Qt.UserRole + 1
    PRICE = Qt.UserRole + 2
    CHANGE = Qt.UserRole + 3
    CHANGEPCT = Qt.UserRole + 4
    DIRECTION = Qt.UserRole + 5

class MarketModel(QAbstractListModel):
    dataChangedAnimated = Signal(int)  # row index for UI animations

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows = []  # list[dict]
        self._index_map = {}  # symbol -> row index

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def roleNames(self):
        return {
            MarketRoles.SYMBOL: QByteArray(b"symbol"),
            MarketRoles.PRICE: QByteArray(b"price"),
            MarketRoles.CHANGE: QByteArray(b"change"),
            MarketRoles.CHANGEPCT: QByteArray(b"changePercent"),
            MarketRoles.DIRECTION: QByteArray(b"direction"),
        }

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        row = self._rows[index.row()]
        if role == MarketRoles.SYMBOL:
            return row["symbol"]
        if role == MarketRoles.PRICE:
            return row["price"]
        if role == MarketRoles.CHANGE:
            return row["change"]
        if role == MarketRoles.CHANGEPCT:
            return row["changePercent"]
        if role == MarketRoles.DIRECTION:
            return row["direction"]
        return None

    def update_from_dict(self, market: dict):
        # market = { "AAPL": {"price":.., "change":.., "change_percent":..}, ...}
        # Insert/update preserving original ordering or new appended at end
        updated_rows = []
        for symbol, payload in market.items():
            price = payload.get("price")
            change = payload.get("change")
            chg_pct = payload.get("change_percent")
            direction = 1 if change and change > 0 else (-1 if change and change < 0 else 0)
            updated_rows.append({
                "symbol": symbol,
                "price": price,
                "change": change,
                "changePercent": chg_pct,
                "direction": direction
            })

        # Simple strategy: full reset for now (optimize later with diff)
        self.beginResetModel()
        self._rows = updated_rows
        self._index_map = {r["symbol"]: i for i, r in enumerate(self._rows)}
        self.endResetModel()
        # Could emit per-row animation triggers
        for i in range(len(self._rows)):
            self.dataChangedAnimated.emit(i)
