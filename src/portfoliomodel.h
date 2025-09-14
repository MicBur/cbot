#pragma once
#include <QAbstractListModel>
#include <QVector>
#include <QString>

struct PortfolioPosition {
    QString ticker;
    double qty = 0.0;
    double avgPrice = 0.0;
    QString side; // long/short
};

class PortfolioModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { TickerRole = Qt::UserRole + 100, QtyRole, AvgPriceRole, SideRole };
    explicit PortfolioModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;

    void updateFromJson(const QByteArray& jsonBytes); // expects array of objects

private:
    QVector<PortfolioPosition> m_rows;
};
