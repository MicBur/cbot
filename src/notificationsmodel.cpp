#include "notificationsmodel.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

NotificationsModel::NotificationsModel(QObject* parent): QAbstractListModel(parent) {}

int NotificationsModel::rowCount(const QModelIndex& parent) const { return parent.isValid()?0:m_rows.size(); }

QVariant NotificationsModel::data(const QModelIndex& index, int role) const {
    if(!index.isValid()||index.row()<0||index.row()>=m_rows.size()) return {};
    const auto &r=m_rows[index.row()];
    switch(role){
        case IdRole: return r.id;
        case TypeRole: return r.type;
        case TitleRole: return r.title;
        case MessageRole: return r.message;
        case TimestampRole: return r.timestamp;
        case ReadRole: return r.read;
    }
    return {};
}

QHash<int,QByteArray> NotificationsModel::roleNames() const {
    return {{IdRole,"id"},{TypeRole,"type"},{TitleRole,"title"},{MessageRole,"message"},{TimestampRole,"timestamp"},{ReadRole,"read"}};
}

void NotificationsModel::updateFromJson(const QByteArray& jsonBytes){
    QJsonParseError err{}; auto doc=QJsonDocument::fromJson(jsonBytes,&err); if(err.error!=QJsonParseError::NoError||!doc.isArray()) return; auto arr=doc.array();
    QVector<NotificationRow> newRows; newRows.reserve(arr.size());
    for(auto v: arr){ if(!v.isObject()) continue; auto o=v.toObject();
        NotificationRow n; n.id=o.value("id").toInt(); n.type=o.value("type").toString(); n.title=o.value("title").toString();
        n.message=o.value("message").toString(); n.timestamp=o.value("timestamp").toString(); n.read=o.value("read").toBool();
        newRows.push_back(n); }
    beginResetModel(); m_rows=std::move(newRows); endResetModel();
}

void NotificationsModel::markRead(int row){
    if(row<0||row>=m_rows.size()) return; auto &r=m_rows[row]; if(!r.read){ r.read=true; QModelIndex idx=index(row); emit dataChanged(idx,idx,{ReadRole}); }
}
