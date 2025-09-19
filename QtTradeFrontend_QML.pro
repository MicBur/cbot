# Qt qmake Project File for Pure QML Frontend
# Usage: qmake && make / mingw32-make / nmake

QT += core quick
CONFIG += c++17 console
CONFIG -= app_bundle

# Add WebSockets support if available
qtHaveModule(websockets) {
    QT += websockets
    DEFINES += WEBSOCKETS_AVAILABLE
    message("WebSockets support enabled")
} else {
    message("WebSockets not available - using HTTP fallback")
}

TEMPLATE = app
TARGET = QtTradeFrontend_QML

# Compiler flags
QMAKE_CXXFLAGS += -Wall -Wextra -Wpedantic

# Defines for QML application
DEFINES += QML_FRONTEND

# Minimal C++ sources
SOURCES += \
    src/main_qml.cpp

# QML Resources
RESOURCES += qml_pure.qrc

# No external dependencies needed for pure QML version
# All data connectivity handled via WebSocket/HTTP in QML

# Development: Enable QML debugging
CONFIG(debug, debug|release) {
    DEFINES += QT_QML_DEBUG
}

# Platform-specific deployment notes
win32 {
    message("Windows: Use windeployqt QtTradeFrontend_QML.exe for deployment")
}

macx {
    message("macOS: Bundle will be created automatically")
}

unix:!macx {
    message("Linux: Desktop entry can be created for system integration")
}

# Version information
VERSION = 1.0.0
QMAKE_TARGET_COMPANY = "QtTrade"
QMAKE_TARGET_PRODUCT = "QtTrade Frontend QML"
QMAKE_TARGET_DESCRIPTION = "Pure QML Trading Frontend"
QMAKE_TARGET_COPYRIGHT = "2024"

message("=== QtTrade Frontend QML (qmake) ===")
message("Qt Version: $$[QT_VERSION]")
message("Target: $$TARGET")
message("====================================")