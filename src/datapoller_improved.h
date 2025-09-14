#pragma once
#include <QObject>
#include <QTimer>
#include <QString>
#include <QThread>
#include <QMutex>
#include <memory>
#include <atomic>
#include <queue>
#include "redisclient_improved.h"

// Forward declarations
class MarketModel;
class PortfolioModel;
class OrdersModel;
class StatusModel;
class NotificationsModel;
class ChartDataModel;
class PredictionsModel;

// Polling strategies
enum class PollingStrategy {
    Fixed,          // Fixed interval polling
    Adaptive,       // Adjust interval based on data changes
    RealTime,       // Low latency polling for active trading
    PowerSave       // Reduced polling when idle
};

// Data update priorities
enum class UpdatePriority {
    Critical = 0,   // Market data, active orders
    High = 1,       // Portfolio positions
    Normal = 2,     // Status, predictions
    Low = 3         // Notifications, historical data
};

// Enhanced Data Poller with background thread and priority queue
class DataPoller : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(qint64 lastLatencyMs READ lastLatencyMs NOTIFY metricsChanged)
    Q_PROPERTY(QString lastPollTime READ lastPollTime NOTIFY metricsChanged)
    Q_PROPERTY(PollingStrategy strategy READ strategy WRITE setStrategy NOTIFY strategyChanged)

public:
    explicit DataPoller(MarketModel* market, const QString& host, int port, const QString& password,
                       PortfolioModel* portfolio = nullptr, OrdersModel* orders = nullptr, 
                       StatusModel* status = nullptr, NotificationsModel* notifications = nullptr,
                       QObject* parent = nullptr);
    ~DataPoller();

    // Control methods
    void start();
    void stop();
    void pause();
    void resume();
    void triggerNow();
    void triggerSpecific(const QStringList& dataTypes);
    
    // Configuration
    void setPollingStrategy(PollingStrategy strategy);
    PollingStrategy strategy() const { return m_strategy; }
    void setBaseInterval(int ms) { m_baseIntervalMs = ms; }
    void setMinInterval(int ms) { m_minIntervalMs = ms; }
    void setMaxInterval(int ms) { m_maxIntervalMs = ms; }
    void setBatchSize(int size) { m_batchSize = size; }
    void setMaxRetries(int retries) { m_maxRetries = retries; }
    
    // Model setters
    void setChartModel(ChartDataModel* model) { m_chartModel = model; }
    void setPredictionsModel(PredictionsModel* model) { m_predictionsModel = model; }
    void setCurrentSymbol(const QString& symbol);
    
    // Performance settings
    void setPerformanceLogging(bool enable) { m_perfLogging = enable; }
    void setThreadedPolling(bool enable);
    void setPriorityBasedPolling(bool enable) { m_priorityPolling = enable; }
    
    // State getters
    bool isConnected() const { return m_connected.load(); }
    qint64 lastLatencyMs() const { return m_lastLatencyMs; }
    QString lastPollTime() const { return m_lastPollTime; }
    int currentIntervalMs() const { return m_currentIntervalMs; }
    
    // Statistics
    struct PollStatistics {
        size_t totalPolls = 0;
        size_t successfulPolls = 0;
        size_t failedPolls = 0;
        size_t dataUpdates = 0;
        qint64 totalLatencyMs = 0;
        qint64 minLatencyMs = INT64_MAX;
        qint64 maxLatencyMs = 0;
        double avgLatencyMs = 0.0;
    };
    
    PollStatistics getStatistics() const;
    void resetStatistics();
    
    // Error information
    QString lastError() const { return m_lastError; }
    int consecutiveErrors() const { return m_consecutiveErrors; }

signals:
    void connectionChanged(bool connected);
    void metricsChanged();
    void strategyChanged();
    void dataUpdated(const QString& dataType);
    void errorOccurred(const QString& error);
    void pollingStarted();
    void pollingStopped();

private slots:
    void poll();
    void pollInBackground();

private:
    // Update task for priority queue
    struct UpdateTask {
        QString key;
        QString dataType;
        UpdatePriority priority;
        std::function<void(const QByteArray&)> updateFunction;
        
        bool operator<(const UpdateTask& other) const {
            return static_cast<int>(priority) > static_cast<int>(other.priority);
        }
    };
    
    // Core components
    std::unique_ptr<RedisClient> m_client;
    std::unique_ptr<RedisConnectionPool> m_connectionPool;
    QTimer m_timer;
    std::unique_ptr<QThread> m_pollingThread;
    
    // Models
    MarketModel* m_marketModel;
    PortfolioModel* m_portfolioModel;
    OrdersModel* m_ordersModel;
    StatusModel* m_statusModel;
    NotificationsModel* m_notificationsModel;
    ChartDataModel* m_chartModel = nullptr;
    PredictionsModel* m_predictionsModel = nullptr;
    
    // Configuration
    QString m_host;
    int m_port;
    QString m_password;
    QString m_currentSymbol;
    
    // Polling settings
    PollingStrategy m_strategy = PollingStrategy::Adaptive;
    int m_baseIntervalMs = 5000;
    int m_minIntervalMs = 1000;
    int m_maxIntervalMs = 30000;
    int m_currentIntervalMs = 5000;
    int m_batchSize = 10;
    int m_maxRetries = 3;
    bool m_perfLogging = false;
    bool m_threadedPolling = false;
    bool m_priorityPolling = true;
    
    // State
    std::atomic<bool> m_connected{false};
    std::atomic<bool> m_running{false};
    std::atomic<bool> m_paused{false};
    qint64 m_lastLatencyMs = 0;
    QString m_lastPollTime;
    QString m_lastError;
    int m_consecutiveErrors = 0;
    int m_dataChangeCount = 0;
    
    // Statistics
    mutable QMutex m_statsMutex;
    PollStatistics m_stats;
    
    // Priority queue for updates
    std::priority_queue<UpdateTask> m_updateQueue;
    mutable QMutex m_queueMutex;
    
    // Helper methods
    void setupUpdateTasks();
    void processUpdateQueue();
    void updateInterval();
    void adjustIntervalAdaptive();
    void adjustIntervalRealTime();
    void adjustIntervalPowerSave();
    bool fetchAndUpdate(const QString& key, const QString& dataType, std::function<void(const QByteArray&)> updateFunc);
    void updateStatistics(bool success, qint64 latencyMs);
    void handleError(const QString& error);
    void clearError();
    
    // Batch operations
    void batchFetch(const QStringList& keys);
    
    // Connection management
    bool ensureConnection();
    std::shared_ptr<RedisClient> getClient();
};

// Background polling worker
class PollingWorker : public QObject {
    Q_OBJECT
public:
    explicit PollingWorker(DataPoller* poller) : m_poller(poller) {}
    
public slots:
    void doPoll();
    
signals:
    void finished();
    void error(const QString& err);
    
private:
    DataPoller* m_poller;
};