#pragma once
#include <QAbstractListModel>
#include <QVector>
#include <QString>

struct OrderRow {
    QString ticker;
    QString side; // buy/sell
    double price = 0.0;
    QString status; // open, filled, cancelled
    QString timestamp;
};

class OrdersModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { OTickerRole = Qt::UserRole + 200, OSideRole, OPriceRole, OStatusRole, OTimestampRole };
    explicit OrdersModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;

    void updateFromJson(const QByteArray& jsonBytes); // array of objects

private:
    QVector<OrderRow> m_rows;
};
