#include "datapoller.h"
#include <QByteArray>
#include <iostream>

DataPoller::DataPoller(MarketModel* market, const QString& host, int port, const QString& password,
                       PortfolioModel* portfolio, OrdersModel* orders, StatusModel* status, NotificationsModel* notifications,
                       QObject* parent)
    : QObject(parent), m_marketModel(market), m_portfolioModel(portfolio), m_ordersModel(orders), m_statusModel(status), m_notificationsModel(notifications), m_host(host), m_port(port), m_password(password) {
    m_client.setHost(host.toStdString());
    m_client.setPort(port);
    if (!password.isEmpty()) m_client.setPassword(password.toStdString());
    m_timer.setInterval(5000); // 5s
    connect(&m_timer, &QTimer::timeout, this, &DataPoller::poll);
}

void DataPoller::start() {
    poll();
    m_timer.start();
}

void DataPoller::poll() {
    auto start = std::chrono::steady_clock::now();
    bool ok = m_client.ping();
    if (ok != m_connected) {
        m_connected = ok;
        emit connectionChanged(m_connected);
    }
    if (!ok) { adjustTimer(false); return; }

    if (auto val = m_client.get("market_data"); val.has_value()) {
        m_marketModel->updateFromJson(QByteArray::fromStdString(*val));
    }
    if (m_portfolioModel) {
        if (auto val = m_client.get("portfolio_positions"); val.has_value()) {
            m_portfolioModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    if (m_ordersModel) {
        if (auto val = m_client.get("active_orders"); val.has_value()) {
            m_ordersModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    if (m_statusModel) {
        if (auto val = m_client.get("system_status"); val.has_value()) {
            m_statusModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    if (m_notificationsModel) {
        if (auto val = m_client.get("notifications"); val.has_value()) {
            m_notificationsModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    // Chart & predictions (optional, nur wenn Modelle gesetzt)
    if (m_chartModel && !m_currentSymbol.isEmpty()) {
        std::string key = std::string("chart_data_") + m_currentSymbol.toStdString();
        if (auto val = m_client.get(key.c_str()); val.has_value()) {
            m_chartModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    if (m_predictionsModel && !m_currentSymbol.isEmpty()) {
        std::string key = std::string("predictions_") + m_currentSymbol.toStdString();
        if (auto val = m_client.get(key.c_str()); val.has_value()) {
            m_predictionsModel->updateFromJson(QByteArray::fromStdString(*val));
        }
    }
    adjustTimer(true);
    auto end = std::chrono::steady_clock::now();
    qint64 ms = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    bool metricsChangedFlag = false;
    if (m_lastLatencyMs != ms) { m_lastLatencyMs = ms; metricsChangedFlag = true; }
    QString nowIso = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    if (m_lastPollTime != nowIso) { m_lastPollTime = nowIso; metricsChangedFlag = true; }
    if (metricsChangedFlag) emit metricsChanged();
    if (m_perfLogging) {
        qInfo() << "poll latency(ms)=" << ms << "interval(ms)=" << m_currentIntervalMs << "failCount=" << m_failCount;
    }
}

void DataPoller::triggerNow() {
    // Direkter Poll-Aufruf; Timer bleibt unverändert
    poll();
}
