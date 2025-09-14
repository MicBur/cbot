#pragma once
#include <QAbstractListModel>
#include <vector>
#include <QString>

struct MarketRow {
    QString symbol;
    double price = 0.0;
    double change = 0.0;
    double changePercent = 0.0;
    int direction = 0; // -1,0,1
};

class MarketModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        SymbolRole = Qt::UserRole + 1,
        PriceRole,
        ChangeRole,
        ChangePercentRole,
        DirectionRole
    };

    explicit MarketModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateFromJson(const QByteArray& jsonBytes);
    // Neue Methode für direkten Map Update (kann intern genutzt werden)
    void updateFromMap(const QJsonObject& rootObj);

signals:
    void rowAnimated(int row);

private:
    std::vector<MarketRow> m_rows;
    // symbol -> index map for quick lookup
    QHash<QString,int> m_indexMap;
};
