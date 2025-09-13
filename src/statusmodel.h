#pragma once
#include <QObject>
#include <QString>
#include <QJsonDocument>
#include <QJsonObject>

class StatusModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool redisConnected READ redisConnected NOTIFY statusChanged)
    Q_PROPERTY(bool postgresConnected READ postgresConnected NOTIFY statusChanged)
    Q_PROPERTY(bool alpacaApiActive READ alpacaApiActive NOTIFY statusChanged)
    Q_PROPERTY(bool grokApiActive READ grokApiActive NOTIFY statusChanged)
    Q_PROPERTY(bool workerRunning READ workerRunning NOTIFY statusChanged)
    Q_PROPERTY(QString lastHeartbeat READ lastHeartbeat NOTIFY statusChanged)
public:
    explicit StatusModel(QObject* parent=nullptr): QObject(parent) {}

    bool redisConnected() const { return m_redisConnected; }
    bool postgresConnected() const { return m_postgresConnected; }
    bool alpacaApiActive() const { return m_alpacaApiActive; }
    bool grokApiActive() const { return m_grokApiActive; }
    bool workerRunning() const { return m_workerRunning; }
    QString lastHeartbeat() const { return m_lastHeartbeat; }

    void updateFromJson(const QByteArray& jsonBytes) {
        QJsonParseError err{}; auto doc=QJsonDocument::fromJson(jsonBytes,&err); if(err.error!=QJsonParseError::NoError||!doc.isObject()) return; auto o=doc.object();
        bool changed=false;
        auto upd=[&](bool &field,bool val){ if(field!=val){ field=val; changed=true; }};
        upd(m_redisConnected, o.value("redis_connected").toBool());
        upd(m_postgresConnected, o.value("postgres_connected").toBool());
        upd(m_alpacaApiActive, o.value("alpaca_api_active").toBool());
        upd(m_grokApiActive, o.value("grok_api_active").toBool());
        upd(m_workerRunning, o.value("worker_running").toBool());
        QString hb = o.value("last_heartbeat").toString(); if (m_lastHeartbeat!=hb){ m_lastHeartbeat=hb; changed=true; }
        if(changed) emit statusChanged();
    }
signals:
    void statusChanged();
private:
    bool m_redisConnected=false;
    bool m_postgresConnected=false;
    bool m_alpacaApiActive=false;
    bool m_grokApiActive=false;
    bool m_workerRunning=false;
    QString m_lastHeartbeat;
};
