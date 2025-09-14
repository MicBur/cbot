#include "ordersmodel.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

OrdersModel::OrdersModel(QObject* parent): QAbstractListModel(parent) {}

int OrdersModel::rowCount(const QModelIndex& parent) const { return parent.isValid()?0:m_rows.size(); }

QVariant OrdersModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid()||index.row()<0||index.row()>=m_rows.size()) return {};
    const auto &r = m_rows[index.row()];
    switch(role){
        case OTickerRole: return r.ticker;
        case OSideRole: return r.side;
        case OPriceRole: return r.price;
        case OStatusRole: return r.status;
        case OTimestampRole: return r.timestamp;
    }
    return {};
}

QHash<int,QByteArray> OrdersModel::roleNames() const {
    return {{OTickerRole,"ticker"},{OSideRole,"side"},{OPriceRole,"price"},{OStatusRole,"status"},{OTimestampRole,"timestamp"}};
}

void OrdersModel::updateFromJson(const QByteArray& jsonBytes){
    QJsonParseError err{}; auto doc=QJsonDocument::fromJson(jsonBytes,&err);
    if(err.error!=QJsonParseError::NoError||!doc.isArray()) return; auto arr=doc.array();
    QVector<OrderRow> newRows; newRows.reserve(arr.size());
    for(auto v: arr){ if(!v.isObject()) continue; auto o=v.toObject();
        OrderRow row; row.ticker=o.value("ticker").toString(); row.side=o.value("side").toString();
        row.price=o.value("price").toDouble(); row.status=o.value("status").toString(); row.timestamp=o.value("timestamp").toString();
        newRows.push_back(row); }
    beginResetModel(); m_rows=std::move(newRows); endResetModel();
}
