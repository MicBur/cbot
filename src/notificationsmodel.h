#pragma once
#include <QAbstractListModel>
#include <QVector>
#include <QString>

struct NotificationRow {
    int id = 0;
    QString type; // success, warning, error, info
    QString title;
    QString message;
    QString timestamp;
    bool read = false;
};

class NotificationsModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { IdRole = Qt::UserRole + 300, TypeRole, TitleRole, MessageRole, TimestampRole, ReadRole };
    explicit NotificationsModel(QObject* parent=nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;

    void updateFromJson(const QByteArray& jsonBytes); // array
    Q_INVOKABLE void markRead(int row);

private:
    QVector<NotificationRow> m_rows;
};
