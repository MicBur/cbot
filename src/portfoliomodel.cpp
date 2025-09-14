#include "portfoliomodel.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

PortfolioModel::PortfolioModel(QObject* parent) : QAbstractListModel(parent) {}

int PortfolioModel::rowCount(const QModelIndex& parent) const { return parent.isValid() ? 0 : m_rows.size(); }

QVariant PortfolioModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};
    const auto &r = m_rows[index.row()];
    switch(role) {
        case TickerRole: return r.ticker;
        case QtyRole: return r.qty;
        case AvgPriceRole: return r.avgPrice;
        case SideRole: return r.side;
    }
    return {};
}

QHash<int,QByteArray> PortfolioModel::roleNames() const {
    return {{TickerRole, "ticker"},{QtyRole,"qty"},{AvgPriceRole,"avgPrice"},{SideRole,"side"}};
}

void PortfolioModel::updateFromJson(const QByteArray& jsonBytes) {
    QJsonParseError err{}; auto doc = QJsonDocument::fromJson(jsonBytes,&err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) return;
    auto arr = doc.array();
    QVector<PortfolioPosition> newRows; newRows.reserve(arr.size());
    for (auto v : arr) {
        if (!v.isObject()) continue; auto o = v.toObject();
        PortfolioPosition p; 
        // Unterstütze sowohl 'ticker' als auch 'symbol' für Kompatibilität
        p.ticker = o.value("ticker").toString();
        if (p.ticker.isEmpty()) p.ticker = o.value("symbol").toString();
        
        // Konvertiere String-Werte zu Zahlen (JSON aus Worker kann String-Format haben)
        QJsonValue qtyVal = o.value("qty");
        p.qty = qtyVal.isString() ? qtyVal.toString().toDouble() : qtyVal.toDouble();
        
        // Unterstütze sowohl 'avg_price' als auch 'avg_entry_price'
        QJsonValue avgPriceVal = o.value("avg_price");
        if (!avgPriceVal.isUndefined()) {
            p.avgPrice = avgPriceVal.isString() ? avgPriceVal.toString().toDouble() : avgPriceVal.toDouble();
        } else {
            QJsonValue entryPriceVal = o.value("avg_entry_price");
            p.avgPrice = entryPriceVal.isString() ? entryPriceVal.toString().toDouble() : entryPriceVal.toDouble();
        }
        
        p.side = o.value("side").toString();
        newRows.push_back(p);
    }
    beginResetModel(); m_rows = std::move(newRows); endResetModel();
}
