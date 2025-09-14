#include "portfoliotab.h"
#include <QDateTimeAxis>
#include <QValueAxis>

PortfolioTab::PortfolioTab(QWidget *parent)
    : QWidget(parent)
{
    QVBoxLayout *layout = new QVBoxLayout(this);

    QLabel *title = new QLabel("Portfolio Equity Curve");
    title->setStyleSheet("color: #00ffff; font-size: 18px;");
    layout->addWidget(title);

    equitySeries = new QLineSeries;
    equitySeries->setName("Equity");
    equitySeries->setColor(QColor(0, 255, 255));

    // Mock data
    QDateTime dateTime = QDateTime::currentDateTime();
    for (int i = 0; i < 10; ++i) {
        equitySeries->append(dateTime.addDays(i).toMSecsSinceEpoch(), 10000 + i * 100);
    }

    chart = new QChart;
    chart->addSeries(equitySeries);
    chart->setTitle("Equity over Time");
    chart->setTheme(QChart::ChartThemeDark);

    QDateTimeAxis *axisX = new QDateTimeAxis;
    axisX->setFormat("dd/MM");
    chart->addAxis(axisX, Qt::AlignBottom);
    equitySeries->attachAxis(axisX);

    QValueAxis *axisY = new QValueAxis;
    axisY->setLabelFormat("$%.0f");
    chart->addAxis(axisY, Qt::AlignLeft);
    equitySeries->attachAxis(axisY);

    chartView = new QChartView(chart);
    chartView->setRenderHint(QPainter::Antialiasing);

    layout->addWidget(chartView);
}

void PortfolioTab::updateData()
{
    // Update from Alpaca API
}