#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QByteArray>
#include <QProcessEnvironment>

#include "marketmodel.h"
#include "datapoller.h"
#include "portfoliomodel.h"
#include "ordersmodel.h"
#include "statusmodel.h"
#include "notificationsmodel.h"
#include "chartdatamodel.h"
#include "predictionsmodel.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("QtTrade");
    QCoreApplication::setApplicationName("QtTradeFrontend");

    // Command line + Env handling for Redis
    QCommandLineParser parser;
    parser.setApplicationDescription("QtTrade Frontend");
    parser.addHelpOption();
    QCommandLineOption hostOpt({"r","redis-host"}, "Redis Host", "host", "127.0.0.1");
    QCommandLineOption portOpt({"p","redis-port"}, "Redis Port", "port", "6380");
    QCommandLineOption passOpt({"w","redis-password"}, "Redis Password", "password", "");
    QCommandLineOption perfOpt({"L","perf-log"}, "Enable performance logging (poll latency)");
    parser.addOption(hostOpt);
    parser.addOption(portOpt);
    parser.addOption(passOpt);
    parser.addOption(perfOpt);
    parser.process(app);

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    QString host = env.value("REDIS_HOST", parser.value(hostOpt));
    int port = env.value("REDIS_PORT", parser.value(portOpt)).toInt();
    QString password = env.value("REDIS_PASSWORD", parser.value(passOpt));
    bool perfLogging = env.value("PERF_LOG", parser.isSet(perfOpt)?"1":"0") == "1";

    MarketModel marketModel;
    PortfolioModel portfolioModel;
    OrdersModel ordersModel;
    StatusModel statusModel;
    NotificationsModel notificationsModel;
    ChartDataModel chartDataModel;
    PredictionsModel predictionsModel;

    DataPoller poller(&marketModel, host, port, password,
                      &portfolioModel, &ordersModel, &statusModel, &notificationsModel);
    poller.setChartModel(&chartDataModel);
    poller.setPredictionsModel(&predictionsModel);
    poller.setPerformanceLogging(perfLogging);
    poller.start();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("marketModel", &marketModel);
    engine.rootContext()->setContextProperty("portfolioModel", &portfolioModel);
    engine.rootContext()->setContextProperty("ordersModel", &ordersModel);
    engine.rootContext()->setContextProperty("statusModel", &statusModel);
    engine.rootContext()->setContextProperty("notificationsModel", &notificationsModel);
    engine.rootContext()->setContextProperty("chartDataModel", &chartDataModel);
    engine.rootContext()->setContextProperty("predictionsModel", &predictionsModel);
    engine.rootContext()->setContextProperty("poller", &poller);

    // QML Logging für Diagnose
    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &ctx, const QString &msg){
        if(type == QtFatalMsg) {
            qCritical() << "FATAL:" << msg;
            abort();
        } else if(type == QtCriticalMsg) {
            qCritical() << msg;
        } else if(type == QtWarningMsg) {
            qWarning() << msg;
        } else {
            qDebug() << msg;
        }
    });

    // Laden über QML Modul (URI Frontend, Version 1.0) statt direkter qrc URL
    engine.loadFromModule(u"Frontend", u"Main");
    if(engine.rootObjects().isEmpty()) {
        qCritical() << "Keine Root QML geladen (Frontend/Main)";
        return -1;
    }

    return app.exec();
}
