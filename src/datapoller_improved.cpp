#include "datapoller_improved.h"
#include <QByteArray>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonDocument>
#include <QDebug>
#include <QThreadPool>
#include <QtConcurrent>
#include <algorithm>

// Models
#include "marketmodel.h"
#include "portfoliomodel.h"
#include "ordersmodel.h"
#include "statusmodel.h"
#include "notificationsmodel.h"
#include "chartdatamodel.h"
#include "predictionsmodel.h"

DataPoller::DataPoller(MarketModel* market, const QString& host, int port, const QString& password,
                       PortfolioModel* portfolio, OrdersModel* orders, StatusModel* status, 
                       NotificationsModel* notifications, QObject* parent)
    : QObject(parent), 
      m_marketModel(market), 
      m_portfolioModel(portfolio), 
      m_ordersModel(orders), 
      m_statusModel(status), 
      m_notificationsModel(notifications),
      m_host(host), 
      m_port(port), 
      m_password(password) {
    
    // Initialize Redis client
    m_client = std::make_unique<RedisClient>(host.toStdString(), port, 0, password.toStdString());
    m_client->setConnectionTimeout(3000);
    m_client->setCommandTimeout(2000);
    m_client->setRetryCount(2);
    m_client->setAutoReconnect(true);
    
    // Initialize connection pool for better performance
    if (m_threadedPolling) {
        m_connectionPool = std::make_unique<RedisConnectionPool>(
            host.toStdString(), port, 0, password.toStdString(), 5
        );
    }
    
    // Setup timer
    m_timer.setInterval(m_currentIntervalMs);
    connect(&m_timer, &QTimer::timeout, this, &DataPoller::poll);
    
    // Setup update tasks
    setupUpdateTasks();
}

DataPoller::~DataPoller() {
    stop();
    if (m_pollingThread && m_pollingThread->isRunning()) {
        m_pollingThread->quit();
        m_pollingThread->wait();
    }
}

void DataPoller::start() {
    if (m_running.load()) return;
    
    m_running = true;
    emit pollingStarted();
    
    // Initial poll
    poll();
    
    // Start timer
    m_timer.start();
}

void DataPoller::stop() {
    if (!m_running.load()) return;
    
    m_running = false;
    m_timer.stop();
    emit pollingStopped();
}

void DataPoller::pause() {
    m_paused = true;
    m_timer.stop();
}

void DataPoller::resume() {
    m_paused = false;
    if (m_running.load()) {
        m_timer.start();
    }
}

void DataPoller::triggerNow() {
    if (m_threadedPolling && !m_pollingThread) {
        setThreadedPolling(true);
    }
    
    if (m_threadedPolling) {
        QtConcurrent::run([this]() { pollInBackground(); });
    } else {
        poll();
    }
}

void DataPoller::triggerSpecific(const QStringList& dataTypes) {
    if (!ensureConnection()) return;
    
    auto start = std::chrono::steady_clock::now();
    
    for (const QString& dataType : dataTypes) {
        if (dataType == "market" && m_marketModel) {
            fetchAndUpdate("market_data", "market", 
                [this](const QByteArray& data) { m_marketModel->updateFromJson(data); });
        } else if (dataType == "portfolio" && m_portfolioModel) {
            fetchAndUpdate("portfolio_positions", "portfolio",
                [this](const QByteArray& data) { m_portfolioModel->updateFromJson(data); });
        } else if (dataType == "orders" && m_ordersModel) {
            fetchAndUpdate("active_orders", "orders",
                [this](const QByteArray& data) { m_ordersModel->updateFromJson(data); });
        }
    }
    
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    updateStatistics(true, duration.count());
}

void DataPoller::setPollingStrategy(PollingStrategy strategy) {
    if (m_strategy != strategy) {
        m_strategy = strategy;
        updateInterval();
        emit strategyChanged();
    }
}

void DataPoller::setCurrentSymbol(const QString& symbol) {
    if (m_currentSymbol != symbol) {
        m_currentSymbol = symbol;
        
        // Trigger immediate update for new symbol data
        if (!symbol.isEmpty() && m_running.load()) {
            QStringList chartUpdates;
            if (m_chartModel) chartUpdates << "chart";
            if (m_predictionsModel) chartUpdates << "predictions";
            
            if (!chartUpdates.isEmpty()) {
                triggerSpecific(chartUpdates);
            }
        }
    }
}

void DataPoller::setThreadedPolling(bool enable) {
    if (m_threadedPolling == enable) return;
    
    m_threadedPolling = enable;
    
    if (enable && !m_pollingThread) {
        m_pollingThread = std::make_unique<QThread>();
        m_pollingThread->start();
    } else if (!enable && m_pollingThread) {
        m_pollingThread->quit();
        m_pollingThread->wait();
        m_pollingThread.reset();
    }
}

DataPoller::PollStatistics DataPoller::getStatistics() const {
    QMutexLocker lock(&m_statsMutex);
    
    if (m_stats.totalPolls > 0) {
        m_stats.avgLatencyMs = static_cast<double>(m_stats.totalLatencyMs) / m_stats.totalPolls;
    }
    
    return m_stats;
}

void DataPoller::resetStatistics() {
    QMutexLocker lock(&m_statsMutex);
    m_stats = PollStatistics();
}

void DataPoller::poll() {
    if (!m_running.load() || m_paused.load()) return;
    
    auto start = std::chrono::steady_clock::now();
    
    // Check connection
    bool wasConnected = m_connected.load();
    bool isConnected = ensureConnection();
    
    if (wasConnected != isConnected) {
        m_connected = isConnected;
        emit connectionChanged(isConnected);
    }
    
    if (!isConnected) {
        handleError("Redis connection failed");
        updateInterval();
        return;
    }
    
    clearError();
    
    if (m_priorityPolling) {
        processUpdateQueue();
    } else {
        // Simple sequential update
        int updatesPerformed = 0;
        
        if (m_marketModel) {
            if (fetchAndUpdate("market_data", "market", 
                [this](const QByteArray& data) { m_marketModel->updateFromJson(data); })) {
                updatesPerformed++;
            }
        }
        
        if (m_portfolioModel) {
            if (fetchAndUpdate("portfolio_positions", "portfolio",
                [this](const QByteArray& data) { m_portfolioModel->updateFromJson(data); })) {
                updatesPerformed++;
            }
        }
        
        if (m_ordersModel) {
            if (fetchAndUpdate("active_orders", "orders",
                [this](const QByteArray& data) { m_ordersModel->updateFromJson(data); })) {
                updatesPerformed++;
            }
        }
        
        if (m_statusModel) {
            // Build status from multiple sources
            QJsonObject status;
            status["redis_connected"] = m_connected.load();
            
            if (auto result = m_client->getWithResult("api_status"); result.hasValue()) {
                QString apiStatus = QString::fromStdString(result.value.value()).replace("\"", "");
                status["alpaca_api_active"] = (apiStatus == "valid");
            }
            
            status["postgres_connected"] = false; // Not implemented
            status["grok_api_active"] = true; // Assumed active
            status["worker_running"] = true; // Assumed running
            status["last_heartbeat"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
            
            QJsonDocument doc(status);
            m_statusModel->updateFromJson(doc.toJson(QJsonDocument::Compact));
            emit dataUpdated("status");
            updatesPerformed++;
        }
        
        if (m_notificationsModel) {
            if (fetchAndUpdate("notifications", "notifications",
                [this](const QByteArray& data) { m_notificationsModel->updateFromJson(data); })) {
                updatesPerformed++;
            }
        }
        
        // Chart and predictions (if symbol selected)
        if (!m_currentSymbol.isEmpty()) {
            if (m_chartModel) {
                std::string key = "chart_data_" + m_currentSymbol.toStdString();
                if (fetchAndUpdate(QString::fromStdString(key), "chart",
                    [this](const QByteArray& data) { m_chartModel->updateFromJson(data); })) {
                    updatesPerformed++;
                }
            }
            
            if (m_predictionsModel) {
                std::string key = "predictions_" + m_currentSymbol.toStdString();
                if (fetchAndUpdate(QString::fromStdString(key), "predictions",
                    [this](const QByteArray& data) { m_predictionsModel->updateFromJson(data); })) {
                    updatesPerformed++;
                }
            }
        }
        
        m_dataChangeCount = updatesPerformed;
    }
    
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    updateStatistics(true, duration.count());
    updateInterval();
    
    // Update metrics for UI
    m_lastLatencyMs = duration.count();
    m_lastPollTime = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    emit metricsChanged();
    
    if (m_perfLogging) {
        qInfo() << "Poll completed - latency:" << duration.count() << "ms"
                << "interval:" << m_currentIntervalMs << "ms"
                << "updates:" << m_dataChangeCount
                << "strategy:" << static_cast<int>(m_strategy);
    }
}

void DataPoller::pollInBackground() {
    // This runs in a background thread
    poll();
}

void DataPoller::setupUpdateTasks() {
    QMutexLocker lock(&m_queueMutex);
    
    // Clear existing queue
    while (!m_updateQueue.empty()) {
        m_updateQueue.pop();
    }
    
    // Add tasks based on priority
    if (m_marketModel) {
        m_updateQueue.push({
            "market_data", "market", UpdatePriority::Critical,
            [this](const QByteArray& data) { m_marketModel->updateFromJson(data); }
        });
    }
    
    if (m_ordersModel) {
        m_updateQueue.push({
            "active_orders", "orders", UpdatePriority::Critical,
            [this](const QByteArray& data) { m_ordersModel->updateFromJson(data); }
        });
    }
    
    if (m_portfolioModel) {
        m_updateQueue.push({
            "portfolio_positions", "portfolio", UpdatePriority::High,
            [this](const QByteArray& data) { m_portfolioModel->updateFromJson(data); }
        });
    }
    
    if (m_statusModel) {
        m_updateQueue.push({
            "status", "status", UpdatePriority::Normal,
            [this](const QByteArray& data) { /* Custom handling in poll() */ }
        });
    }
    
    if (m_notificationsModel) {
        m_updateQueue.push({
            "notifications", "notifications", UpdatePriority::Low,
            [this](const QByteArray& data) { m_notificationsModel->updateFromJson(data); }
        });
    }
}

void DataPoller::processUpdateQueue() {
    QMutexLocker lock(&m_queueMutex);
    
    if (m_updateQueue.empty()) {
        setupUpdateTasks();
    }
    
    // Process updates based on priority
    int updatesPerformed = 0;
    int maxUpdatesPerPoll = m_batchSize;
    
    std::vector<UpdateTask> tasksToProcess;
    
    while (!m_updateQueue.empty() && updatesPerformed < maxUpdatesPerPoll) {
        UpdateTask task = m_updateQueue.top();
        m_updateQueue.pop();
        tasksToProcess.push_back(task);
        updatesPerformed++;
    }
    
    lock.unlock();
    
    // Execute tasks (potentially in parallel)
    if (m_threadedPolling && tasksToProcess.size() > 1) {
        // Parallel execution
        QList<QFuture<void>> futures;
        
        for (const auto& task : tasksToProcess) {
            futures.append(QtConcurrent::run([this, task]() {
                fetchAndUpdate(task.key, task.dataType, task.updateFunction);
            }));
        }
        
        // Wait for all to complete
        for (auto& future : futures) {
            future.waitForFinished();
        }
    } else {
        // Sequential execution
        for (const auto& task : tasksToProcess) {
            fetchAndUpdate(task.key, task.dataType, task.updateFunction);
        }
    }
    
    m_dataChangeCount = updatesPerformed;
}

void DataPoller::updateInterval() {
    int oldInterval = m_currentIntervalMs;
    
    switch (m_strategy) {
        case PollingStrategy::Fixed:
            m_currentIntervalMs = m_baseIntervalMs;
            break;
            
        case PollingStrategy::Adaptive:
            adjustIntervalAdaptive();
            break;
            
        case PollingStrategy::RealTime:
            adjustIntervalRealTime();
            break;
            
        case PollingStrategy::PowerSave:
            adjustIntervalPowerSave();
            break;
    }
    
    // Apply limits
    m_currentIntervalMs = std::clamp(m_currentIntervalMs, m_minIntervalMs, m_maxIntervalMs);
    
    if (oldInterval != m_currentIntervalMs) {
        m_timer.setInterval(m_currentIntervalMs);
    }
}

void DataPoller::adjustIntervalAdaptive() {
    // Adjust based on data change rate
    if (m_dataChangeCount > 5) {
        // Lots of changes - poll more frequently
        m_currentIntervalMs = static_cast<int>(m_currentIntervalMs * 0.8);
    } else if (m_dataChangeCount == 0) {
        // No changes - poll less frequently
        m_currentIntervalMs = static_cast<int>(m_currentIntervalMs * 1.2);
    }
    
    // Consider error rate
    if (m_consecutiveErrors > 3) {
        // Back off when having connection issues
        m_currentIntervalMs = static_cast<int>(m_currentIntervalMs * 1.5);
    }
}

void DataPoller::adjustIntervalRealTime() {
    // Check market hours (simplified - you'd want proper market hours checking)
    QTime currentTime = QTime::currentTime();
    bool marketHours = (currentTime.hour() >= 9 && currentTime.hour() < 16);
    
    if (marketHours) {
        m_currentIntervalMs = m_minIntervalMs; // Poll as fast as allowed
    } else {
        m_currentIntervalMs = m_baseIntervalMs; // Normal polling outside market hours
    }
}

void DataPoller::adjustIntervalPowerSave() {
    // Reduce polling when no user activity detected
    // This is simplified - in real app you'd track user activity
    
    if (m_dataChangeCount == 0 && m_consecutiveErrors == 0) {
        // No changes and no errors - system is stable
        m_currentIntervalMs = m_maxIntervalMs;
    } else {
        m_currentIntervalMs = m_baseIntervalMs;
    }
}

bool DataPoller::fetchAndUpdate(const QString& key, const QString& dataType, 
                               std::function<void(const QByteArray&)> updateFunc) {
    auto client = getClient();
    if (!client) return false;
    
    auto result = client->getWithResult(key.toStdString());
    
    if (result.hasValue()) {
        QByteArray data = QByteArray::fromStdString(result.value.value());
        updateFunc(data);
        emit dataUpdated(dataType);
        return true;
    } else if (result.hasError() && result.error != RedisError::None) {
        QString errorMsg = QString("Failed to fetch %1: %2")
            .arg(dataType)
            .arg(QString::fromStdString(result.errorMessage));
        handleError(errorMsg);
    }
    
    return false;
}

void DataPoller::batchFetch(const QStringList& keys) {
    auto client = getClient();
    if (!client) return;
    
    std::vector<std::string> keyVec;
    for (const QString& key : keys) {
        keyVec.push_back(key.toStdString());
    }
    
    auto result = client->mget(keyVec);
    
    if (result.hasValue()) {
        const auto& values = result.value.value();
        
        for (size_t i = 0; i < values.size() && i < keys.size(); ++i) {
            if (values[i].has_value()) {
                QString key = keys[static_cast<int>(i)];
                QByteArray data = QByteArray::fromStdString(values[i].value());
                
                // Route to appropriate model based on key
                if (key == "market_data" && m_marketModel) {
                    m_marketModel->updateFromJson(data);
                    emit dataUpdated("market");
                } else if (key == "portfolio_positions" && m_portfolioModel) {
                    m_portfolioModel->updateFromJson(data);
                    emit dataUpdated("portfolio");
                }
                // ... etc
            }
        }
    }
}

void DataPoller::updateStatistics(bool success, qint64 latencyMs) {
    QMutexLocker lock(&m_statsMutex);
    
    m_stats.totalPolls++;
    if (success) {
        m_stats.successfulPolls++;
    } else {
        m_stats.failedPolls++;
    }
    
    m_stats.totalLatencyMs += latencyMs;
    m_stats.minLatencyMs = std::min(m_stats.minLatencyMs, latencyMs);
    m_stats.maxLatencyMs = std::max(m_stats.maxLatencyMs, latencyMs);
}

void DataPoller::handleError(const QString& error) {
    m_lastError = error;
    m_consecutiveErrors++;
    emit errorOccurred(error);
    
    if (m_perfLogging) {
        qWarning() << "DataPoller error:" << error << "consecutive:" << m_consecutiveErrors;
    }
}

void DataPoller::clearError() {
    if (m_consecutiveErrors > 0) {
        m_lastError.clear();
        m_consecutiveErrors = 0;
    }
}

bool DataPoller::ensureConnection() {
    auto client = getClient();
    if (!client) return false;
    
    if (!client->isConnected()) {
        return client->connect();
    }
    
    // Verify connection with ping
    return client->ping();
}

std::shared_ptr<RedisClient> DataPoller::getClient() {
    if (m_connectionPool) {
        return m_connectionPool->acquire();
    } else {
        return std::shared_ptr<RedisClient>(m_client.get(), [](RedisClient*){});
    }
}

// PollingWorker implementation
void PollingWorker::doPoll() {
    try {
        m_poller->poll();
        emit finished();
    } catch (const std::exception& e) {
        emit error(QString::fromStdString(e.what()));
    }
}