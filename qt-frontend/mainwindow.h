#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QStackedWidget>
#include <QTimer>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QGraphicsDropShadowEffect>
#include "dashboardtab.h"
#include "chartstab.h"
#include "portfoliotab.h"
#include "tradestab.h"
#include "settingstab.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void switchToDashboard();
    void switchToCharts();
    void switchToPortfolio();
    void switchToTrades();
    void switchToSettings();
    void updateData();

private:
    QStackedWidget *stackedWidget;
    QTimer *timer;
    DashboardTab *dashboardTab;
    ChartsTab *chartsTab;
    PortfolioTab *portfolioTab;
    TradesTab *tradesTab;
    SettingsTab *settingsTab;

    void setupUI();
    void setupSidebar();
    void applyGlowEffect(QWidget *widget);
};

#endif // MAINWINDOW_H