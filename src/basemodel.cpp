#include "basemodel.h"
#include <QJsonParseError>
#include <QDebug>
#include <QDateTime>

BaseModel::BaseModel(QObject* parent) : QAbstractListModel(parent) {
}

void BaseModel::updateFromJson(const QByteArray& jsonData) {
    if (jsonData.isEmpty()) {
        setError("Empty JSON data received");
        return;
    }
    
    ScopedTimer timer(this);
    ModelUpdateGuard guard(this);
    
    executeSafely([&]() {
        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &parseError);
        
        if (parseError.error != QJsonParseError::NoError) {
            // Try Python dict format
            QString dataStr = QString::fromUtf8(jsonData);
            if (dataStr.startsWith("{'") || dataStr.startsWith("{\"")) {
                QString jsonStr = dataStr;
                jsonStr.replace("'", "\"");
                doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &parseError);
            }
            
            if (parseError.error != QJsonParseError::NoError) {
                QString errorMsg = QString("JSON parse error at offset %1: %2")
                    .arg(parseError.offset)
                    .arg(parseError.errorString());
                setError(errorMsg);
                guard.setFailed(true);
                emit validationFailed(errorMsg);
                return;
            }
        }
        
        if (!validateJsonData(doc)) {
            guard.setFailed(true);
            return;
        }
        
        clearError();
        
        if (doc.isObject()) {
            updateFromJsonObject(doc.object());
        } else if (doc.isArray()) {
            updateFromJsonArray(doc.array());
        } else {
            setError("JSON data is neither object nor array");
            guard.setFailed(true);
            emit validationFailed("Invalid JSON structure");
            return;
        }
        
        incrementUpdateCount();
        m_lastUpdateTime = QDateTime::currentMSecsSinceEpoch();
        emit lastUpdateTimeChanged();
    });
}

bool BaseModel::validateJsonData(const QJsonDocument& doc) const {
    // Basic validation - derived classes can override for specific validation
    if (doc.isNull() || doc.isEmpty()) {
        const_cast<BaseModel*>(this)->setError("Invalid or empty JSON document");
        return false;
    }
    return true;
}

BaseModel::PerformanceMetrics BaseModel::getMetrics() const {
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    return m_metrics;
}

void BaseModel::resetMetrics() {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    m_metrics = PerformanceMetrics();
}

void BaseModel::setLoading(bool loading) {
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void BaseModel::setError(const QString& error) {
    if (m_lastError != error) {
        m_lastError = error;
        emit errorChanged();
        
        if (!error.isEmpty()) {
            qWarning() << metaObject()->className() << "error:" << error;
            m_metrics.failedUpdates++;
        }
    }
}

void BaseModel::clearError() {
    if (!m_lastError.isEmpty()) {
        m_lastError.clear();
        emit errorChanged();
    }
}

void BaseModel::incrementUpdateCount() {
    m_updateCount++;
    emit updateCountChanged();
}

double BaseModel::parseDouble(const QJsonValue& value, double defaultValue) {
    if (value.isDouble()) {
        return value.toDouble();
    } else if (value.isString()) {
        bool ok;
        double result = value.toString().toDouble(&ok);
        return ok ? result : defaultValue;
    }
    return defaultValue;
}

qint64 BaseModel::parseInt64(const QJsonValue& value, qint64 defaultValue) {
    if (value.isDouble()) {
        return static_cast<qint64>(value.toDouble());
    } else if (value.isString()) {
        bool ok;
        qint64 result = value.toString().toLongLong(&ok);
        return ok ? result : defaultValue;
    }
    return defaultValue;
}

QString BaseModel::parseString(const QJsonValue& value, const QString& defaultValue) {
    if (value.isString()) {
        return value.toString();
    } else if (value.isDouble()) {
        return QString::number(value.toDouble());
    }
    return defaultValue;
}

void BaseModel::updateMetrics(qint64 processingTimeMs) {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    
    m_metrics.totalUpdates++;
    m_metrics.totalProcessingTimeMs += processingTimeMs;
    m_metrics.minProcessingTimeMs = std::min(m_metrics.minProcessingTimeMs, processingTimeMs);
    m_metrics.maxProcessingTimeMs = std::max(m_metrics.maxProcessingTimeMs, processingTimeMs);
    
    if (m_metrics.totalUpdates > 0) {
        m_metrics.avgProcessingTimeMs = m_metrics.totalProcessingTimeMs / static_cast<qint64>(m_metrics.totalUpdates);
    }
}

// ScopedTimer implementation
BaseModel::ScopedTimer::ScopedTimer(BaseModel* model) 
    : m_model(model), m_start(std::chrono::steady_clock::now()) {
}

BaseModel::ScopedTimer::~ScopedTimer() {
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - m_start);
    m_model->updateMetrics(duration.count());
}