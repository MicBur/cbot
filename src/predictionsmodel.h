#pragma once
#include <QAbstractListModel>
#include <QVector>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

struct ForecastPoint { QString t; double v; };

class PredictionsModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { TimeRole=Qt::UserRole+1, ValueRole };
    explicit PredictionsModel(QObject* parent=nullptr): QAbstractListModel(parent) {}
    int rowCount(const QModelIndex& parent=QModelIndex()) const override { return parent.isValid()?0:m_points.size(); }
    QVariant data(const QModelIndex& idx, int role) const override {
        if(!idx.isValid()||idx.row()<0||idx.row()>=m_points.size()) return {};
        const auto &p = m_points[idx.row()];
        switch(role){ case TimeRole: return p.t; case ValueRole: return p.v; default: return {}; }
    }
    QHash<int,QByteArray> roleNames() const override { return {{TimeRole,"t"},{ValueRole,"v"}}; }
    Q_INVOKABLE void updateFromJson(const QByteArray& bytes) {
        QJsonParseError err{}; auto doc=QJsonDocument::fromJson(bytes,&err); if(err.error!=QJsonParseError::NoError||!doc.isArray()) return; auto arr=doc.array(); QVector<ForecastPoint> fresh; fresh.reserve(arr.size()); for(auto v:arr){ if(!v.isObject()) continue; auto o=v.toObject(); ForecastPoint fp{ o.value("t").toString(), o.value("v").toDouble() }; fresh.push_back(fp);} beginResetModel(); m_points=std::move(fresh); endResetModel(); emit changed(); }
    const QVector<ForecastPoint>& points() const { return m_points; }
signals: void changed();
private: QVector<ForecastPoint> m_points; };
