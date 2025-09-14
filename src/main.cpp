#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QByteArray>
#include <QProcessEnvironment>
#include <QTimer>

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

    // Redis Models reaktiviert für echte Daten
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
    // Context Properties für echte Redis-Daten
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
            QTimer::singleShot(3000, []() { abort(); });
        } else if(type == QtCriticalMsg) {
            qCritical() << "CRITICAL:" << msg;
        } else if(type == QtWarningMsg) {
            qWarning() << "WARNING:" << msg;
        } else {
            qDebug() << "DEBUG:" << msg;
        }
    });

    qDebug() << "=== QtTradeFrontend startet ===";
    qDebug() << "Qt Version:" << QT_VERSION_STR;
    qDebug() << "Lade QML Modul Frontend/MainStep3...";

    // Laden über QML Modul (URI Frontend, Version 1.0) - MainStep3 für Main.qml ohne DropShadow
    engine.loadFromModule(u"Frontend", u"MainStep3");
    if(engine.rootObjects().isEmpty()) {
        qCritical() << "FEHLER: Keine Root QML geladen (Frontend/MainStep3)";
        qCritical() << "Verfügbare QML Module:";
        // Debug: 3 Sekunden warten bevor Exit damit Fehler sichtbar wird
        QTimer::singleShot(3000, [](){ qApp->exit(-1); });
        return app.exec();
    }
    
    qDebug() << "QML erfolgreich geladen, Root Objects:" << engine.rootObjects().size();

    return app.exec();
}
