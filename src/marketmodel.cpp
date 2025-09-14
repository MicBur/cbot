#include "marketmodel.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonValueRef>
#include <QDebug>
#include <unordered_set>

MarketModel::MarketModel(QObject* parent) : QAbstractListModel(parent) {}

int MarketModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_rows.size());
}

QVariant MarketModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) return {};
    const auto& r = m_rows[static_cast<size_t>(index.row())];
    switch (role) {
        case SymbolRole: return r.symbol;
        case PriceRole: return r.price;
        case ChangeRole: return r.change;
        case ChangePercentRole: return r.changePercent;
        case DirectionRole: return r.direction;
        default: return {};
    }
}

QHash<int, QByteArray> MarketModel::roleNames() const {
    return {
        {SymbolRole, "symbol"},
        {PriceRole, "price"},
        {ChangeRole, "change"},
        {ChangePercentRole, "changePercent"},
        {DirectionRole, "direction"},
    };
}

void MarketModel::updateFromJson(const QByteArray& jsonBytes) {
    // Erst versuchen, als JSON zu parsen
    QJsonParseError err{};
    auto doc = QJsonDocument::fromJson(jsonBytes, &err);
    if (err.error == QJsonParseError::NoError && doc.isObject()) {
        // Erfolgreich als JSON geparst
        updateFromMap(doc.object());
        return;
    }
    
    // Falls JSON-Parsing fehlschlägt, versuche Python-Dict Format zu konvertieren
    QString dataStr = QString::fromUtf8(jsonBytes);
    if (dataStr.startsWith("{'") || dataStr.startsWith("{\"")) {
        // Python-Dict Format: Ersetze Single Quotes mit Double Quotes für JSON
        QString jsonStr = dataStr;
        jsonStr.replace("'", "\"");
        
        // Versuche nochmal als JSON zu parsen
        auto docRetry = QJsonDocument::fromJson(jsonStr.toUtf8(), &err);
        if (err.error == QJsonParseError::NoError && docRetry.isObject()) {
            updateFromMap(docRetry.object());
            return;
        }
    }
    
    // Falls beide Versuche fehlschlagen, gib Debug-Info aus
    qDebug() << "MarketModel: Failed to parse data format:" << dataStr.left(100) << "...";
}

void MarketModel::updateFromMap(const QJsonObject& rootObj) {
    // Track seen symbols
    QSet<QString> seen;

    // 1. Update existing rows where symbol still present
    for (auto it = rootObj.begin(); it != rootObj.end(); ++it) {
        const QString sym = it.key();
        if (!it.value().isObject()) continue;
        seen.insert(sym);
        auto obj = it.value().toObject();
        double price = obj.value("price").toDouble();
        double change = obj.value("change").toDouble();
        double changePct = obj.value("change_percent").toDouble();
        int direction = change > 0 ? 1 : (change < 0 ? -1 : 0);

        if (m_indexMap.contains(sym)) {
            int idx = m_indexMap.value(sym);
            if (idx >= 0 && idx < m_rows.size()) {
                auto &row = m_rows[static_cast<size_t>(idx)];
                bool anyChanged = (row.price != price) || (row.change != change) || (row.changePercent != changePct) || (row.direction != direction);
                if (anyChanged) {
                    row.price = price;
                    row.change = change;
                    row.changePercent = changePct;
                    row.direction = direction;
                    QModelIndex qmi = index(idx);
                    QVector<int> roles { PriceRole, ChangeRole, ChangePercentRole, DirectionRole };
                    emit dataChanged(qmi, qmi, roles);
                    emit rowAnimated(idx);
                }
            }
        }
    }

    // 2. Remove rows not present anymore (iterate backwards for index stability)
    for (int i = static_cast<int>(m_rows.size()) - 1; i >= 0; --i) {
        const QString &sym = m_rows[static_cast<size_t>(i)].symbol;
        if (!seen.contains(sym)) {
            beginRemoveRows(QModelIndex(), i, i);
            m_rows.erase(m_rows.begin() + i);
            endRemoveRows();
        }
    }

    // Rebuild index map (after removals, before potential inserts)
    m_indexMap.clear();
    for (int i = 0; i < static_cast<int>(m_rows.size()); ++i) {
        m_indexMap.insert(m_rows[static_cast<size_t>(i)].symbol, i);
    }

    // 3. Insert new symbols (preserve order of JSON iteration for those not existing)
    QList<MarketRow> toInsert;
    for (auto it = rootObj.begin(); it != rootObj.end(); ++it) {
        const QString sym = it.key();
        if (!it.value().isObject()) continue;
        if (!m_indexMap.contains(sym)) {
            auto obj = it.value().toObject();
            MarketRow row;
            row.symbol = sym;
            row.price = obj.value("price").toDouble();
            row.change = obj.value("change").toDouble();
            row.changePercent = obj.value("change_percent").toDouble();
            row.direction = row.change > 0 ? 1 : (row.change < 0 ? -1 : 0);
            toInsert.append(row);
        }
    }
    if (!toInsert.isEmpty()) {
        int start = static_cast<int>(m_rows.size());
        int end = start + toInsert.size() - 1;
        beginInsertRows(QModelIndex(), start, end);
        m_rows.insert(m_rows.end(), toInsert.begin(), toInsert.end());
        endInsertRows();
        // Update map for newly inserted rows
        for (int i = start; i <= end; ++i) {
            m_indexMap.insert(m_rows[static_cast<size_t>(i)].symbol, i);
            emit rowAnimated(i);
        }
    }
}
