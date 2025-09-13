#pragma once
#include <QObject>
#include <QTimer>
#include <memory>
#include "redisclient.h"
#include "marketmodel.h"
#include "portfoliomodel.h"
#include "ordersmodel.h"
#include "statusmodel.h"
#include "notificationsmodel.h"
#include "chartdatamodel.h"
#include "predictionsmodel.h"

class DataPoller : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString currentSymbol READ currentSymbol WRITE setCurrentSymbol NOTIFY currentSymbolChanged)
    Q_PROPERTY(qint64 lastLatencyMs READ lastLatencyMs NOTIFY metricsChanged)
    Q_PROPERTY(QString lastPollTime READ lastPollTime NOTIFY metricsChanged)
public:
    explicit DataPoller(MarketModel* market,
                        const QString& host = "127.0.0.1", int port = 6380, const QString& password = QString(),
                        PortfolioModel* portfolio = nullptr,
                        OrdersModel* orders = nullptr,
                        StatusModel* status = nullptr,
                        NotificationsModel* notifications = nullptr,
                        QObject* parent = nullptr);

    bool isConnected() const { return m_connected; }
    QString currentSymbol() const { return m_currentSymbol; }
    void setCurrentSymbol(const QString& sym) { if (sym==m_currentSymbol) return; m_currentSymbol = sym; emit currentSymbolChanged(m_currentSymbol); }
    void setChartModel(ChartDataModel* m) { m_chartModel = m; }
    void setPredictionsModel(PredictionsModel* m) { m_predictionsModel = m; }
    qint64 lastLatencyMs() const { return m_lastLatencyMs; }
    QString lastPollTime() const { return m_lastPollTime; }
    void setPerformanceLogging(bool enabled) { m_perfLogging = enabled; }
    Q_INVOKABLE void triggerNow();

public slots:
    void start();
    void poll();

signals:
    void connectionChanged(bool c);
    void currentSymbolChanged(const QString& s);
    void metricsChanged();

private:
    MarketModel* m_marketModel;
    PortfolioModel* m_portfolioModel {nullptr};
    OrdersModel* m_ordersModel {nullptr};
    StatusModel* m_statusModel {nullptr};
    NotificationsModel* m_notificationsModel {nullptr};
    ChartDataModel* m_chartModel {nullptr};
    PredictionsModel* m_predictionsModel {nullptr};
    QTimer m_timer;
    RedisClient m_client;
    QString m_host;
    int m_port;
    QString m_password;
    bool m_connected {false};
    QString m_currentSymbol {"AAPL"};
    qint64 m_lastLatencyMs { -1 };
    QString m_lastPollTime; // ISO 8601
    bool m_perfLogging {false};
    // Backoff
    int m_baseIntervalMs {5000};
    int m_currentIntervalMs {5000};
    int m_failCount {0};
    int m_maxIntervalMs {30000};
    void adjustTimer(bool success) {
        if (success) {
            if (m_failCount>0) {
                m_failCount = 0;
                m_currentIntervalMs = m_baseIntervalMs;
                m_timer.setInterval(m_currentIntervalMs);
            }
        } else {
            m_failCount++;
            // exponentieller Backoff (1,2,4,8,...) * base bis max
            qint64 next = (qint64)m_baseIntervalMs * (1LL << (m_failCount-1));
            if (next > m_maxIntervalMs) next = m_maxIntervalMs;
            m_currentIntervalMs = (int)next;
            m_timer.setInterval(m_currentIntervalMs);
        }
    }
};
