import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Qt.labs.settings 1.0

import "services"
import "components"

ApplicationWindow {
    id: root
    width: 1400
    height: 900
    visible: true
    title: "QtTrade Frontend - Pure QML"
    
    // Theme and Settings
    property alias theme: themeLoader.item
    property alias dataService: dataServiceLoader.item
    
    // Application settings
    Settings {
        id: appSettings
        property string theme: "dark"
        property bool notifications: true
        property string lastSymbol: "AAPL"
        property string redisHost: "127.0.0.1"
        property int redisPort: 6380
        property string redisPassword: ""
        property int windowWidth: 1400
        property int windowHeight: 900
        
        // Restore window size
        Component.onCompleted: {
            root.width = windowWidth
            root.height = windowHeight
        }
        
        // Save window size on close
        Component.onDestruction: {
            windowWidth = root.width
            windowHeight = root.height
        }
    }
    
    // Theme Loader
    Loader {
        id: themeLoader
        source: "Theme.qml"
        onLoaded: {
            console.log("Theme loaded successfully")
        }
    }
    
    // Data Service Loader
    Loader {
        id: dataServiceLoader
        source: "services/DataService.qml"
        onLoaded: {
            console.log("DataService loaded successfully")
            // Configure with settings
            item.redisHost = appSettings.redisHost
            item.redisPort = appSettings.redisPort
            item.redisPassword = appSettings.redisPassword
        }
    }
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bg : "#1e1e1e"
        
        // Top Bar
        Rectangle {
            id: topBar
            anchors.top: parent.top
            height: 56
            width: parent.width
            color: theme ? theme.bgElevated : "#2d2d2d"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // App Title
                Text {
                    text: "QtTrade"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: theme ? theme.accent : "#64b5f6"
                }
                
                // Connection Status
                Row {
                    spacing: 8
                    
                    StatusIndicator {
                        status: dataService ? dataService.connected : false
                        label: dataService ? dataService.connectionStatus : "Disconnected"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: dataService && dataService.statusData ? dataService.statusData.postgresConnected : false
                        label: "PostgreSQL"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: dataService && dataService.statusData ? dataService.statusData.workerRunning : false
                        label: "Worker"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: dataService && dataService.statusData ? dataService.statusData.alpacaApiActive : false
                        label: "Alpaca"
                        size: 12
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Notifications Badge
                Rectangle {
                    width: 40
                    height: 32
                    radius: 16
                    color: theme ? theme.accentAlt : "#424242"
                    border.color: theme ? theme.accent : "#64b5f6"
                    border.width: notificationDrawer.visible ? 2 : 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🔔"
                        font.pixelSize: 16
                    }
                    
                    // Unread count badge
                    Rectangle {
                        visible: dataService && dataService.notificationsData && dataService.notificationsData.getUnreadCount() > 0
                        width: 20
                        height: 20
                        radius: 10
                        color: theme ? theme.danger : "#f44336"
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -4
                        anchors.topMargin: -4
                        
                        Text {
                            anchors.centerIn: parent
                            text: dataService && dataService.notificationsData ? Math.min(dataService.notificationsData.getUnreadCount(), 99) : ""
                            font.pixelSize: 10
                            color: "white"
                            font.weight: Font.Bold
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: notificationDrawer.visible = !notificationDrawer.visible
                    }
                }
                
                // Current Time
                Text {
                    text: Qt.formatTime(new Date(), "HH:mm:ss")
                    font.pixelSize: 16
                    font.family: "Consolas, monospace"
                    color: theme ? theme.text : "#ffffff"
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm:ss")
                    }
                }
            }
        }
        
        // Main Content Area
        RowLayout {
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0
            
            // Side Navigation
            ModernSideNav {
                id: sideNav
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                
                onCurrentIndexChanged: {
                    stackView.currentIndex = currentIndex
                }
            }
            
            // Main Content Stack
            StackLayout {
                id: stackView
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: sideNav.currentIndex
                
                // Market Dashboard
                Item {
                    ModernMarketView {
                        anchors.fill: parent
                        anchors.margins: 16
                        marketModel: dataService ? dataService.marketData : null
                    }
                }
                
                // Charts View
                Item {
                    ModernChartView {
                        anchors.fill: parent
                        anchors.margins: 16
                        marketModel: dataService ? dataService.marketData : null
                        symbol: appSettings.lastSymbol
                        onSymbolChanged: appSettings.lastSymbol = symbol
                    }
                }
                
                // Portfolio View
                Item {
                    ModernPortfolioView {
                        anchors.fill: parent
                        anchors.margins: 16
                        portfolioModel: dataService ? dataService.portfolioData : null
                    }
                }
                
                // Orders View
                Item {
                    ModernOrdersView {
                        anchors.fill: parent
                        anchors.margins: 16
                        ordersModel: dataService ? dataService.ordersData : null
                    }
                }
                
                // Settings View
                Item {
                    ModernSettingsView {
                        anchors.fill: parent
                        anchors.margins: 16
                        settings: appSettings
                        dataService: root.dataService
                    }
                }
            }
        }
        
        // Notification Drawer
        NotificationDrawer {
            id: notificationDrawer
            anchors.top: topBar.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 400
            visible: false
            
            notificationsModel: dataService ? dataService.notificationsData : null
            
            Behavior on visible {
                NumberAnimation {
                    duration: theme ? theme.durMed : 200
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        // Connection Error Overlay
        Rectangle {
            anchors.fill: parent
            color: "#aa000000"
            visible: dataService && !dataService.connected
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from going through
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: 400
                height: 200
                radius: 12
                color: theme ? theme.bgElevated : "#2d2d2d"
                border.color: theme ? theme.danger : "#f44336"
                border.width: 2
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    
                    Text {
                        text: "🔌 Verbindung verloren"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: theme ? theme.danger : "#f44336"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: "Die Verbindung zum Server wurde unterbrochen.\\nReconnect wird automatisch versucht..."
                        font.pixelSize: 16
                        color: theme ? theme.textDim : "#aaaaaa"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    Text {
                        text: "Status: " + (dataService ? dataService.connectionStatus : "Unknown")
                        font.pixelSize: 14
                        color: theme ? theme.text : "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            Behavior on visible {
                NumberAnimation {
                    duration: theme ? theme.durMed : 200
                }
            }
        }
    }
    
    // Global keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: sideNav.currentIndex = 0
    }
    
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: sideNav.currentIndex = 1
    }
    
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: sideNav.currentIndex = 2
    }
    
    Shortcut {
        sequence: "Ctrl+4"
        onActivated: sideNav.currentIndex = 3
    }
    
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: notificationDrawer.visible = !notificationDrawer.visible
    }
    
    Shortcut {
        sequence: "F5"
        onActivated: {
            if (dataService) {
                dataService.loadInitialData()
            }
        }
    }
}