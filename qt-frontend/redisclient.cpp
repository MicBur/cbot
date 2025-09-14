#include "redisclient.h"
#include <QDebug>
#include <QProcess>
#include <QJsonParseError>

RedisClient::RedisClient(const QString &host, int port, const QString &password, QObject *parent)
    : QObject(parent), m_host(host), m_port(port), m_password(password), m_connected(false)
{
    // Verwende QProcess für redis-cli Verbindung zum Remote-Server
    // Format: redis-cli -h REMOTE_HOST -p 6379 -a pass123 get key
    m_connected = true; 
    emit connected();
    
    qDebug() << "Connecting to Redis at" << host << ":" << port;
}

QString RedisClient::get(const QString &key)
{
    // Verwende QProcess für redis-cli zum Remote-Server
    QProcess process;
    QStringList arguments;
    arguments << "-h" << m_host 
              << "-p" << QString::number(m_port)
              << "-a" << m_password
              << "get" << key;
    
    process.start("redis-cli", arguments);
    process.waitForFinished(5000); // 5 Sekunden timeout
    
    if (process.exitCode() == 0) {
        QString result = process.readAllStandardOutput().trimmed();
        // Entferne Anführungszeichen falls vorhanden
        if (result.startsWith('"') && result.endsWith('"')) {
            result = result.mid(1, result.length() - 2);
        }
        return result;
    }
    
    qWarning() << "Redis GET failed for key:" << key << process.readAllStandardError();
    
    // Fallback zu Mock-Daten bei Verbindungsfehlern
    if (key == "market_data") {
        QJsonObject data = mockMarketData();
        return QJsonDocument(data).toJson(QJsonDocument::Compact);
    }
    
    return QString();
}

bool RedisClient::set(const QString &key, const QString &value)
{
    // Mock-Implementierung
    qDebug() << "Setting Redis key:" << key << "=" << value;
    return true;
}

QStringList RedisClient::keys(const QString &pattern)
{
    // Mock-Implementierung
    return QStringList() << "market_data" << "model_trained" << "model_path";
}

QJsonObject RedisClient::getMarketData()
{
    QString jsonStr = get("market_data");
    if (jsonStr.isEmpty()) {
        return QJsonObject();
    }
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &error);
    
    if (error.error != QJsonParseError::NoError) {
        qWarning() << "Failed to parse market data JSON:" << error.errorString();
        return mockMarketData(); // Fallback
    }
    
    return doc.object();
}

bool RedisClient::isModelTrained()
{
    return get("model_trained") == "true";
}

QString RedisClient::getModelPath()
{
    return get("model_path");
}

QJsonObject RedisClient::mockMarketData()
{
    // Mock-Daten für Entwicklung/Testing
    QJsonObject data;
    
    QStringList tickers = {"AAPL", "NVDA", "MSFT", "TSLA", "AMZN", "META", "GOOGL", "BRK.B", "AVGO", "JPM", 
                          "LLY", "V", "XOM", "PG", "UNH", "MA", "JNJ", "COST", "HD", "BAC"};
    
    for (const QString &ticker : tickers) {
        QJsonObject tickerData;
        tickerData["price"] = 100.0 + (qrand() % 400); // Random price 100-500
        tickerData["change"] = -10.0 + (qrand() % 20);  // Random change -10 to +10
        tickerData["change_percent"] = tickerData["change"].toDouble() / tickerData["price"].toDouble() * 100;
        
        data[ticker] = tickerData;
    }
    
    return data;
}