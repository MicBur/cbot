#pragma once
#include <QAbstractListModel>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTimer>
#include <memory>
#include <chrono>
#include <shared_mutex>

/**
 * @brief Base class for all data models in the trading application
 * 
 * Provides common functionality for:
 * - Thread-safe data updates
 * - JSON parsing and validation
 * - Performance monitoring
 * - Change notifications
 * - Error handling
 */
class BaseModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged)
    Q_PROPERTY(int updateCount READ updateCount NOTIFY updateCountChanged)
    Q_PROPERTY(qint64 lastUpdateTime READ lastUpdateTime NOTIFY lastUpdateTimeChanged)

public:
    explicit BaseModel(QObject* parent = nullptr);
    virtual ~BaseModel() = default;

    // State management
    bool isLoading() const { return m_loading; }
    QString lastError() const { return m_lastError; }
    int updateCount() const { return m_updateCount; }
    qint64 lastUpdateTime() const { return m_lastUpdateTime; }

    // Update methods
    virtual void updateFromJson(const QByteArray& jsonData);
    virtual void updateFromJsonObject(const QJsonObject& obj) = 0;
    virtual void updateFromJsonArray(const QJsonArray& array) = 0;
    
    // Validation
    virtual bool validateJsonData(const QJsonDocument& doc) const;
    
    // Performance metrics
    struct PerformanceMetrics {
        size_t totalUpdates = 0;
        size_t failedUpdates = 0;
        qint64 totalProcessingTimeMs = 0;
        qint64 avgProcessingTimeMs = 0;
        qint64 minProcessingTimeMs = INT64_MAX;
        qint64 maxProcessingTimeMs = 0;
    };
    
    PerformanceMetrics getMetrics() const;
    void resetMetrics();

signals:
    void loadingChanged();
    void errorChanged();
    void updateCountChanged();
    void lastUpdateTimeChanged();
    void dataUpdateStarted();
    void dataUpdateCompleted(bool success);
    void validationFailed(const QString& reason);

protected:
    // Helper methods for derived classes
    void setLoading(bool loading);
    void setError(const QString& error);
    void clearError();
    void incrementUpdateCount();
    
    // Thread-safe update helpers
    template<typename T>
    void safeUpdate(T& target, const T& value, std::function<void()> notifyFunc = nullptr);
    
    template<typename Func>
    void executeSafely(Func func);
    
    // JSON parsing helpers
    static double parseDouble(const QJsonValue& value, double defaultValue = 0.0);
    static qint64 parseInt64(const QJsonValue& value, qint64 defaultValue = 0);
    static QString parseString(const QJsonValue& value, const QString& defaultValue = QString());
    
    // Timing helpers
    class ScopedTimer {
    public:
        explicit ScopedTimer(BaseModel* model);
        ~ScopedTimer();
        
    private:
        BaseModel* m_model;
        std::chrono::steady_clock::time_point m_start;
    };
    
    // Member variables
    mutable std::shared_mutex m_mutex;
    bool m_loading = false;
    QString m_lastError;
    int m_updateCount = 0;
    qint64 m_lastUpdateTime = 0;
    
    // Performance tracking
    mutable PerformanceMetrics m_metrics;
    
private:
    void updateMetrics(qint64 processingTimeMs);
};

// Template implementations
template<typename T>
void BaseModel::safeUpdate(T& target, const T& value, std::function<void()> notifyFunc) {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    if (target != value) {
        target = value;
        lock.unlock();
        if (notifyFunc) {
            notifyFunc();
        }
    }
}

template<typename Func>
void BaseModel::executeSafely(Func func) {
    try {
        func();
    } catch (const std::exception& e) {
        setError(QString("Exception: %1").arg(e.what()));
    } catch (...) {
        setError("Unknown exception occurred");
    }
}

/**
 * @brief RAII helper for automatic model state management
 */
class ModelUpdateGuard {
public:
    explicit ModelUpdateGuard(BaseModel* model) : m_model(model) {
        if (m_model) {
            m_model->setLoading(true);
            m_model->dataUpdateStarted();
        }
    }
    
    ~ModelUpdateGuard() {
        if (m_model) {
            m_model->setLoading(false);
            m_model->dataUpdateCompleted(!m_failed);
        }
    }
    
    void setFailed(bool failed = true) { m_failed = failed; }
    
private:
    BaseModel* m_model;
    bool m_failed = false;
};

/**
 * @brief Interface for models that support filtering
 */
class IFilterable {
public:
    virtual ~IFilterable() = default;
    virtual void setFilter(const QString& filter) = 0;
    virtual QString filter() const = 0;
    virtual void clearFilter() = 0;
};

/**
 * @brief Interface for models that support sorting
 */
class ISortable {
public:
    enum class SortOrder {
        Ascending,
        Descending
    };
    
    virtual ~ISortable() = default;
    virtual void setSortColumn(int column) = 0;
    virtual void setSortOrder(SortOrder order) = 0;
    virtual int sortColumn() const = 0;
    virtual SortOrder sortOrder() const = 0;
};

/**
 * @brief Interface for models that support real-time updates
 */
class IRealTimeUpdatable {
public:
    virtual ~IRealTimeUpdatable() = default;
    virtual void enableRealTimeUpdates(bool enable) = 0;
    virtual bool realTimeUpdatesEnabled() const = 0;
    virtual void setUpdateInterval(int milliseconds) = 0;
    virtual int updateInterval() const = 0;
};