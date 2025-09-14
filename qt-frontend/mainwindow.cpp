#include "mainwindow.h"
#include <QApplication>
#include <QDesktopWidget>
#include <QPropertyAnimation>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setWindowTitle("Qt Trade - Tradebot Agent");
    setWindowFlags(Qt::FramelessWindowHint);
    setAttribute(Qt::WA_TranslucentBackground);
    resize(1200, 800);

    setupUI();

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &MainWindow::updateData);
    timer->start(5000); // 5 seconds poll
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUI()
{
    QWidget *centralWidget = new QWidget;
    setCentralWidget(centralWidget);

    QHBoxLayout *mainLayout = new QHBoxLayout(centralWidget);

    // Sidebar
    QWidget *sidebar = new QWidget;
    sidebar->setFixedWidth(200);
    sidebar->setStyleSheet("background-color: #0a0a0a; border-right: 1px solid #00ffff;");
    QVBoxLayout *sidebarLayout = new QVBoxLayout(sidebar);

    QPushButton *dashboardBtn = new QPushButton("Dashboard");
    QPushButton *chartsBtn = new QPushButton("Charts");
    QPushButton *portfolioBtn = new QPushButton("Portfolio");
    QPushButton *tradesBtn = new QPushButton("Trades");
    QPushButton *settingsBtn = new QPushButton("Settings");

    QString btnStyle = "QPushButton { background-color: #0a0a0a; color: #00ffff; border: none; padding: 10px; text-align: left; }"
                       "QPushButton:hover { background-color: #00ffff; color: #0a0a0a; }";

    dashboardBtn->setStyleSheet(btnStyle);
    chartsBtn->setStyleSheet(btnStyle);
    portfolioBtn->setStyleSheet(btnStyle);
    tradesBtn->setStyleSheet(btnStyle);
    settingsBtn->setStyleSheet(btnStyle);

    connect(dashboardBtn, &QPushButton::clicked, this, &MainWindow::switchToDashboard);
    connect(chartsBtn, &QPushButton::clicked, this, &MainWindow::switchToCharts);
    connect(portfolioBtn, &QPushButton::clicked, this, &MainWindow::switchToPortfolio);
    connect(tradesBtn, &QPushButton::clicked, this, &MainWindow::switchToTrades);
    connect(settingsBtn, &QPushButton::clicked, this, &MainWindow::switchToSettings);

    sidebarLayout->addWidget(dashboardBtn);
    sidebarLayout->addWidget(chartsBtn);
    sidebarLayout->addWidget(portfolioBtn);
    sidebarLayout->addWidget(tradesBtn);
    sidebarLayout->addWidget(settingsBtn);
    sidebarLayout->addStretch();

    mainLayout->addWidget(sidebar);

    // Stacked Widget
    stackedWidget = new QStackedWidget;
    mainLayout->addWidget(stackedWidget);

    dashboardTab = new DashboardTab;
    chartsTab = new ChartsTab;
    portfolioTab = new PortfolioTab;
    tradesTab = new TradesTab;
    settingsTab = new SettingsTab;

    stackedWidget->addWidget(dashboardTab);
    stackedWidget->addWidget(chartsTab);
    stackedWidget->addWidget(portfolioTab);
    stackedWidget->addWidget(tradesTab);
    stackedWidget->addWidget(settingsTab);

    applyGlowEffect(sidebar);
}

void MainWindow::switchToDashboard()
{
    stackedWidget->setCurrentWidget(dashboardTab);
}

void MainWindow::switchToCharts()
{
    stackedWidget->setCurrentWidget(chartsTab);
}

void MainWindow::switchToPortfolio()
{
    stackedWidget->setCurrentWidget(portfolioTab);
}

void MainWindow::switchToTrades()
{
    stackedWidget->setCurrentWidget(tradesTab);
}

void MainWindow::switchToSettings()
{
    stackedWidget->setCurrentWidget(settingsTab);
}

void MainWindow::updateData()
{
    // Poll Redis for updates
    dashboardTab->updateData();
    chartsTab->updateData();
    portfolioTab->updateData();
    tradesTab->updateData();
}

void MainWindow::applyGlowEffect(QWidget *widget)
{
    QGraphicsDropShadowEffect *effect = new QGraphicsDropShadowEffect;
    effect->setBlurRadius(20);
    effect->setColor(QColor(0, 255, 255));
    effect->setOffset(0, 0);
    widget->setGraphicsEffect(effect);
}