#include "dashboardtab.h"
#include <QHeaderView>
#include <QJsonObject>
#include <QJsonArray>

DashboardTab::DashboardTab(QWidget *parent)
    : QWidget(parent)
{
    QVBoxLayout *layout = new QVBoxLayout(this);

    QLabel *title = new QLabel("Top 20 US Tickers");
    title->setStyleSheet("color: #00ffff; font-size: 18px;");
    layout->addWidget(title);

    tableView = new QTableView;
    model = new QStandardItemModel(20, 3, this);
    model->setHeaderData(0, Qt::Horizontal, "Ticker");
    model->setHeaderData(1, Qt::Horizontal, "Price");
    model->setHeaderData(2, Qt::Horizontal, "Change %");

    tableView->setModel(model);
    tableView->setStyleSheet("QTableView { background-color: #0a0a0a; color: #00ffff; gridline-color: #00ffff; }"
                             "QHeaderView::section { background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff; }");
    tableView->horizontalHeader()->setStretchLastSection(true);

    layout->addWidget(tableView);

    manager = new QNetworkAccessManager(this);
    connect(manager, &QNetworkAccessManager::finished, this, &DashboardTab::onReplyFinished);

    fetchGrokData();
}

void DashboardTab::updateData()
{
    fetchGrokData();
}

void DashboardTab::fetchGrokData()
{
    // Mock Grok API call - in real app, use actual API
    QJsonDocument doc;
    QJsonArray array;
    for (int i = 0; i < tickers.size(); ++i) {
        QJsonObject obj;
        obj["ticker"] = tickers[i];
        obj["price"] = 100.0 + i * 10; // Mock
        obj["change"] = 1.5;
        array.append(obj);
    }
    doc.setArray(array);

    // Simulate reply
    onReplyFinished(nullptr); // For now, use mock
}

void DashboardTab::onReplyFinished(QNetworkReply *reply)
{
    // Parse JSON and update model
    for (int i = 0; i < tickers.size(); ++i) {
        model->setData(model->index(i, 0), tickers[i]);
        model->setData(model->index(i, 1), QString::number(100.0 + i * 10, 'f', 2));
        model->setData(model->index(i, 2), "+1.5%");
    }
}