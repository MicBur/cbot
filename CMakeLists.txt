cmake_minimum_required(VERSION 3.21)
project(QtTradeFrontend LANGUAGES CXX)

# QML Language Server Konfig (Editor Autocomplete / weniger Warnungen)
set(QT_QML_GENERATE_QMLLS_INI ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick)

# hiredis (expect installed or provide path)
find_path(HIREDIS_INCLUDE_DIR hiredis/hiredis.h)
find_library(HIREDIS_LIB hiredis)
if(NOT HIREDIS_INCLUDE_DIR OR NOT HIREDIS_LIB)
    message(WARNING "hiredis not found - build will fail if Redis code is enabled.")
endif()

set(SOURCES
    src/main.cpp
    src/redisclient.cpp
    src/marketmodel.cpp
    src/datapoller.cpp
    src/portfoliomodel.cpp
    src/ordersmodel.cpp
    src/statusmodel.cpp
    src/notificationsmodel.cpp
)

set(HEADERS
    src/redisclient.h
    src/marketmodel.h
    src/datapoller.h
    src/portfoliomodel.h
    src/ordersmodel.h
    src/statusmodel.h
    src/notificationsmodel.h
    src/chartdatamodel.h
    src/predictionsmodel.h
)

qt_add_executable(QtTradeFrontend
    ${SOURCES}
    ${HEADERS}
)

qt_add_qml_module(QtTradeFrontend
    URI Frontend
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/components/HeaderBar.qml
        qml/components/SideNav.qml
        qml/components/MarketList.qml
        qml/components/StatusBadge.qml
)

target_include_directories(QtTradeFrontend PRIVATE ${HIREDIS_INCLUDE_DIR})

target_link_libraries(QtTradeFrontend
    PRIVATE
        Qt::Core
        Qt::Quick
        ${HIREDIS_LIB}
)

# Windows: deploy steps comment (use windeployqt after build)

install(TARGETS QtTradeFrontend
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
