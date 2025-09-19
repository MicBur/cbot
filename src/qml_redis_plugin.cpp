#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QtQml>
#include <QObject>
#include <QTimer>
#include <QJsonObject>
#include <QJsonDocument>

#ifdef HIREDIS_AVAILABLE
#include <hiredis.h>
#endif

class QmlRedisClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY portChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)

public:
    explicit QmlRedisClient(QObject *parent = nullptr) 
        : QObject(parent), m_connected(false), m_host("127.0.0.1"), m_port(6380)
    {
#ifdef HIREDIS_AVAILABLE
        m_context = nullptr;
#endif
        
        // Auto-reconnect timer
        m_reconnectTimer = new QTimer(this);
        m_reconnectTimer->setSingleShot(false);
        m_reconnectTimer->setInterval(5000); // 5 seconds
        connect(m_reconnectTimer, &QTimer::timeout, this, &QmlRedisClient::tryConnect);
    }
    
    ~QmlRedisClient() {
#ifdef HIREDIS_AVAILABLE
        if (m_context) {
            redisFree(m_context);
        }
#endif
    }

    bool connected() const { return m_connected; }
    QString host() const { return m_host; }
    int port() const { return m_port; }
    QString password() const { return m_password; }

    void setHost(const QString &host) {
        if (m_host != host) {
            m_host = host;
            emit hostChanged();
            tryConnect();
        }
    }

    void setPort(int port) {
        if (m_port != port) {
            m_port = port;
            emit portChanged();
            tryConnect();
        }
    }

    void setPassword(const QString &password) {
        if (m_password != password) {
            m_password = password;
            emit passwordChanged();
            tryConnect();
        }
    }

public slots:
    void connectToRedis() {
        tryConnect();
    }
    
    void disconnect() {
#ifdef HIREDIS_AVAILABLE
        if (m_context) {
            redisFree(m_context);
            m_context = nullptr;
        }
#endif
        setConnected(false);
        m_reconnectTimer->stop();
    }
    
    QVariant get(const QString &key) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return QVariant();
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "GET %s", key.toUtf8().data());
        if (!reply) return QVariant();
        
        QVariant result;
        if (reply->type == REDIS_REPLY_STRING) {
            result = QString::fromUtf8(reply->str, reply->len);
        }
        
        freeReplyObject(reply);
        return result;
#else
        Q_UNUSED(key)
        return QVariant();
#endif
    }
    
    QVariantMap hgetall(const QString &key) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return QVariantMap();
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "HGETALL %s", key.toUtf8().data());
        if (!reply || reply->type != REDIS_REPLY_ARRAY) {
            if (reply) freeReplyObject(reply);
            return QVariantMap();
        }
        
        QVariantMap result;
        for (size_t i = 0; i < reply->elements; i += 2) {
            if (i + 1 < reply->elements) {
                QString field = QString::fromUtf8(reply->element[i]->str);
                QString value = QString::fromUtf8(reply->element[i + 1]->str);
                result[field] = value;
            }
        }
        
        freeReplyObject(reply);
        return result;
#else
        Q_UNUSED(key)
        return QVariantMap();
#endif
    }
    
    QStringList keys(const QString &pattern) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return QStringList();
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "KEYS %s", pattern.toUtf8().data());
        if (!reply || reply->type != REDIS_REPLY_ARRAY) {
            if (reply) freeReplyObject(reply);
            return QStringList();
        }
        
        QStringList result;
        for (size_t i = 0; i < reply->elements; i++) {
            result.append(QString::fromUtf8(reply->element[i]->str));
        }
        
        freeReplyObject(reply);
        return result;
#else
        Q_UNUSED(pattern)
        return QStringList();
#endif
    }
    
    bool set(const QString &key, const QString &value) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return false;
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "SET %s %s", 
                                                     key.toUtf8().data(), 
                                                     value.toUtf8().data());
        if (!reply) return false;
        
        bool success = (reply->type == REDIS_REPLY_STATUS && 
                       QString::fromUtf8(reply->str) == "OK");
        
        freeReplyObject(reply);
        return success;
#else
        Q_UNUSED(key)
        Q_UNUSED(value)
        return false;
#endif
    }
    
    bool hset(const QString &key, const QString &field, const QString &value) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return false;
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "HSET %s %s %s", 
                                                     key.toUtf8().data(),
                                                     field.toUtf8().data(),
                                                     value.toUtf8().data());
        if (!reply) return false;
        
        bool success = (reply->type == REDIS_REPLY_INTEGER);
        
        freeReplyObject(reply);
        return success;
#else
        Q_UNUSED(key)
        Q_UNUSED(field)
        Q_UNUSED(value)
        return false;
#endif
    }
    
    bool ping() {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return false;
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "PING");
        if (!reply) return false;
        
        bool success = (reply->type == REDIS_REPLY_STATUS && 
                       QString::fromUtf8(reply->str) == "PONG");
        
        freeReplyObject(reply);
        return success;
#else
        return false;
#endif
    }
    
    QVariantList lrange(const QString &key, int start = 0, int stop = -1) {
#ifdef HIREDIS_AVAILABLE
        if (!m_context) return QVariantList();
        
        redisReply *reply = (redisReply*)redisCommand(m_context, "LRANGE %s %d %d", 
                                                     key.toUtf8().data(), start, stop);
        if (!reply || reply->type != REDIS_REPLY_ARRAY) {
            if (reply) freeReplyObject(reply);
            return QVariantList();
        }
        
        QVariantList result;
        for (size_t i = 0; i < reply->elements; i++) {
            if (reply->element[i]->type == REDIS_REPLY_STRING) {
                result.append(QString::fromUtf8(reply->element[i]->str));
            }
        }
        
        freeReplyObject(reply);
        return result;
#else
        Q_UNUSED(key)
        Q_UNUSED(start)
        Q_UNUSED(stop)
        return QVariantList();
#endif
    }

signals:
    void connectedChanged();
    void hostChanged();
    void portChanged();
    void passwordChanged();
    void dataReceived(const QString &channel, const QVariant &data);

private slots:
    void tryConnect() {
#ifdef HIREDIS_AVAILABLE
        if (m_context) {
            redisFree(m_context);
            m_context = nullptr;
        }
        
        struct timeval timeout = { 1, 500000 }; // 1.5 seconds
        m_context = redisConnectWithTimeout(m_host.toUtf8().data(), m_port, timeout);
        
        if (!m_context || m_context->err) {
            if (m_context) {
                qWarning() << "Redis connection error:" << m_context->errstr;
                redisFree(m_context);
                m_context = nullptr;
            }
            setConnected(false);
            if (!m_reconnectTimer->isActive()) {
                m_reconnectTimer->start();
            }
            return;
        }
        
        // Authenticate if password is provided
        if (!m_password.isEmpty()) {
            redisReply *reply = (redisReply*)redisCommand(m_context, "AUTH %s", m_password.toUtf8().data());
            if (!reply || reply->type == REDIS_REPLY_ERROR) {
                qWarning() << "Redis authentication failed";
                if (reply) freeReplyObject(reply);
                redisFree(m_context);
                m_context = nullptr;
                setConnected(false);
                return;
            }
            freeReplyObject(reply);
        }
        
        // Test connection with PING
        redisReply *reply = (redisReply*)redisCommand(m_context, "PING");
        if (!reply || reply->type != REDIS_REPLY_STATUS) {
            qWarning() << "Redis PING failed";
            if (reply) freeReplyObject(reply);
            redisFree(m_context);
            m_context = nullptr;
            setConnected(false);
            return;
        }
        freeReplyObject(reply);
        
        setConnected(true);
        m_reconnectTimer->stop();
        qDebug() << "Redis connected successfully";
#else
        qWarning() << "Redis support not available - compiled without hiredis";
        setConnected(false);
#endif
    }

private:
    void setConnected(bool connected) {
        if (m_connected != connected) {
            m_connected = connected;
            emit connectedChanged();
        }
    }

    bool m_connected;
    QString m_host;
    int m_port;
    QString m_password;
    QTimer *m_reconnectTimer;

#ifdef HIREDIS_AVAILABLE
    redisContext *m_context;
#endif
};

class QmlRedisPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override {
        qmlRegisterType<QmlRedisClient>(uri, 1, 0, "RedisClient");
    }
};

#include "qml_redis_plugin.moc"