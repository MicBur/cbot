#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QTimer>
#include <QLoggingCategory>

// Minimal C++ entry point for pure QML application
int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    
    // Application metadata
    QCoreApplication::setOrganizationName("QtTrade");
    QCoreApplication::setApplicationName("QtTradeFrontend");
    QCoreApplication::setApplicationVersion("1.0.0");
    
    // Enable QML debugging in debug builds
#ifdef QT_DEBUG
    QLoggingCategory::setFilterRules("qt.qml.binding.removal.info=true");
#endif
    
    // QML Application Engine
    QQmlApplicationEngine engine;
    
    // Add import paths for custom QML modules
    engine.addImportPath("qrc:/qml");
    engine.addImportPath(":/qml");
    
    // Global QML logging handler
    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &ctx, const QString &msg){
        QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
        QString typeStr;
        
        switch(type) {
        case QtDebugMsg:    typeStr = "DEBUG"; break;
        case QtInfoMsg:     typeStr = "INFO"; break;
        case QtWarningMsg:  typeStr = "WARN"; break;
        case QtCriticalMsg: typeStr = "CRITICAL"; break;
        case QtFatalMsg:    typeStr = "FATAL"; break;
        }
        
        qDebug().noquote() << QString("[%1] %2: %3").arg(timestamp, typeStr, msg);
        
        if(type == QtFatalMsg) {
            QTimer::singleShot(1000, []() { abort(); });
        }
    });
    
    qInfo() << "=== QtTrade Frontend (Pure QML) ===";
    qInfo() << "Qt Version:" << QT_VERSION_STR;
    qInfo() << "Loading QML application...";
    
    // Load main QML file
    const QUrl url(u"qrc:/qml/MainQML.qml"_qs);
    
    // Handle QML loading errors
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML file:" << url;
            QCoreApplication::exit(-1);
        } else {
            qInfo() << "QML application loaded successfully";
        }
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root QML objects found";
        return -1;
    }
    
    return app.exec();
}