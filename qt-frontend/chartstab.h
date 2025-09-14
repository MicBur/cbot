#ifndef CHARTSTAB_H
#define CHARTSTAB_H

#include <QWidget>
#include <QChartView>
#include <QCandlestickSeries>
#include <QLineSeries>
#include <QChart>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QComboBox>
#include <QLabel>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDateTime>

class ChartsTab : public QWidget
{
    Q_OBJECT

public:
    ChartsTab(QWidget *parent = nullptr);
    void updateData();

private:
    QChartView *chartView;
    QCandlestickSeries *series;
    QChart *chart;
    QComboBox *tickerCombo;

    void setupChart();
};

#endif // CHARTSTAB_H