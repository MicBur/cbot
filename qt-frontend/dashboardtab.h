#ifndef DASHBOARDTAB_H
#define DASHBOARDTAB_H

#include <QWidget>
#include <QTableView>
#include <QStandardItemModel>
#include <QVBoxLayout>
#include <QLabel>
#include <QTimer>
#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class DashboardTab : public QWidget
{
    Q_OBJECT

public:
    DashboardTab(QWidget *parent = nullptr);
    void updateData();

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    QTableView *tableView;
    QStandardItemModel *model;
    QNetworkAccessManager *manager;
    QStringList tickers = {"AAPL", "NVDA", "MSFT", "TSLA", "AMZN", "META", "GOOGL", "BRK.B", "AVGO", "JPM", "LLY", "V", "XOM", "PG", "UNH", "MA", "JNJ", "COST", "HD", "BAC"};

    void fetchGrokData();
};

#endif // DASHBOARDTAB_H