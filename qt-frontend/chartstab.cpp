#include "chartstab.h"
#include <QCandlestickSet>
#include <QDateTime>

ChartsTab::ChartsTab(QWidget *parent)
    : QWidget(parent)
{
    QVBoxLayout *layout = new QVBoxLayout(this);

    QHBoxLayout *topLayout = new QHBoxLayout;
    QLabel *label = new QLabel("Select Ticker:");
    label->setStyleSheet("color: #00ffff;");
    tickerCombo = new QComboBox;
    tickerCombo->addItems({"AAPL", "NVDA", "MSFT", "TSLA", "AMZN"});
    tickerCombo->setStyleSheet("background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff;");

    topLayout->addWidget(label);
    topLayout->addWidget(tickerCombo);
    topLayout->addStretch();

    layout->addLayout(topLayout);

    setupChart();
    layout->addWidget(chartView);
}

void ChartsTab::setupChart()
{
    series = new QCandlestickSeries;
    series->setName("AAPL Candlestick");
    series->setIncreasingColor(QColor(0, 255, 0));
    series->setDecreasingColor(QColor(255, 0, 0));

    // Mock data
    QDateTime dateTime = QDateTime::currentDateTime();
    for (int i = 0; i < 10; ++i) {
        QCandlestickSet *set = new QCandlestickSet(100 + i, 105 + i, 95 + i, 102 + i, dateTime.addSecs(i * 900).toMSecsSinceEpoch());
        series->append(set);
    }

    chart = new QChart;
    chart->addSeries(series);
    chart->setTitle("15-Min OHLCV");
    chart->setTheme(QChart::ChartThemeDark);

    chartView = new QChartView(chart);
    chartView->setRenderHint(QPainter::Antialiasing);
}

void ChartsTab::updateData()
{
    // Update chart with new data from Redis
    // For now, mock update
}