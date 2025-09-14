#ifndef REDISCLIENT_H
#define REDISCLIENT_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QTimer>

// Redis Client für Qt (vereinfacht - normalerweise würde man hiredis verwenden)
class RedisClient : public QObject
{
    Q_OBJECT

public:
    explicit RedisClient(const QString &host = "localhost", int port = 6379, const QString &password = "", QObject *parent = nullptr);
    
    // Redis-Befehle
    QString get(const QString &key);
    bool set(const QString &key, const QString &value);
    QStringList keys(const QString &pattern = "*");
    
    // Spezielle Methoden für unser Trading-System
    QJsonObject getMarketData();
    bool isModelTrained();
    QString getModelPath();

signals:
    void connected();
    void disconnected();
    void dataUpdated(const QJsonObject &data);

private:
    QString m_host;
    int m_port;
    QString m_password;
    bool m_connected;
    
    // Mock-Implementierung (in echter App würde hiredis verwendet)
    QJsonObject mockMarketData();
};

#endif // REDISCLIENT_H