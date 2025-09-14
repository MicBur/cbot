cmake_minimum_required(VERSION 3.16)
project(QtTrade)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Charts Network)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_executable(QtTrade
    main.cpp
    mainwindow.cpp
    mainwindow.h
    dashboardtab.cpp
    dashboardtab.h
    chartstab.cpp
    chartstab.h
    portfoliotab.cpp
    portfoliotab.h
    tradestab.cpp
    tradestab.h
    settingstab.cpp
    settingstab.h
)

target_link_libraries(QtTrade Qt6::Core Qt6::Widgets Qt6::Charts Qt6::Network hiredis)