#pragma once
#include <QAbstractListModel>
#include <QVector>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

struct Candle {
    double o; double h; double l; double c; QString t; // t = timestamp/string
};

class ChartDataModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { OpenRole=Qt::UserRole+1, HighRole, LowRole, CloseRole, TimeRole };
    explicit ChartDataModel(QObject* parent=nullptr): QAbstractListModel(parent) {}

    int rowCount(const QModelIndex& parent=QModelIndex()) const override { return parent.isValid()?0:m_data.size(); }
    QVariant data(const QModelIndex& idx, int role) const override {
        if(!idx.isValid()||idx.row()<0||idx.row()>=m_data.size()) return {};
        const auto &cd = m_data[idx.row()];
        switch(role){
            case OpenRole: return cd.o; case HighRole: return cd.h; case LowRole: return cd.l; case CloseRole: return cd.c; case TimeRole: return cd.t; default: return {};
        }
    }
    QHash<int,QByteArray> roleNames() const override {
        return { {OpenRole,"o"},{HighRole,"h"},{LowRole,"l"},{CloseRole,"c"},{TimeRole,"t"} };
    }

    Q_INVOKABLE void updateFromJson(const QByteArray& bytes) {
        QJsonParseError err{}; auto doc = QJsonDocument::fromJson(bytes,&err); if(err.error!=QJsonParseError::NoError||!doc.isArray()) return;
        auto arr = doc.array(); QVector<Candle> fresh; fresh.reserve(arr.size());
        for (auto v: arr) { if(!v.isObject()) continue; auto o=v.toObject(); Candle cd{ o.value("o").toDouble(), o.value("h").toDouble(), o.value("l").toDouble(), o.value("c").toDouble(), o.value("t").toString() }; fresh.push_back(cd);}        
        beginResetModel(); m_data = std::move(fresh); endResetModel(); emit changed();
    }

    const QVector<Candle>& candles() const { return m_data; }

signals:
    void changed();
private:
    QVector<Candle> m_data;
};
