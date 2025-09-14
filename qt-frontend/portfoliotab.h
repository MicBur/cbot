#ifndef PORTFOLIOTAB_H
#define PORTFOLIOTAB_H

#include <QWidget>
#include <QLineSeries>
#include <QChart>
#include <QChartView>
#include <QVBoxLayout>
#include <QLabel>

class PortfolioTab : public QWidget
{
    Q_OBJECT

public:
    PortfolioTab(QWidget *parent = nullptr);
    void updateData();

private:
    QChartView *chartView;
    QLineSeries *equitySeries;
    QChart *chart;
};

#endif // PORTFOLIOTAB_H