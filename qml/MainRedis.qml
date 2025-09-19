import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Qt.labs.settings 1.0

import Frontend 1.0
import "services"
import "components"

ApplicationWindow {
    id: root
    width: 1400
    height: 900
    visible: true
    title: "QtTrade Frontend - Direct Redis Integration"
    
    // Theme and Settings
    property alias theme: themeLoader.item
    property alias redisService: redisServiceLoader.item
    
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
            console.log("✅ Theme loaded successfully")
        }
    }
    
    // Redis Data Service Loader
    Loader {
        id: redisServiceLoader
        source: "services/RedisDataService.qml"
        onLoaded: {
            console.log("✅ RedisDataService loaded successfully")
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
        
        // Top Bar with Redis Status
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
                
                // App Title with Redis indicator
                Row {
                    spacing: 12
                    
                    Text {
                        text: "QtTrade"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: theme ? theme.accent : "#64b5f6"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: redisService && redisService.connected ? "#4caf50" : "#f44336"
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: "R"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: "white"
                        }
                        
                        ToolTip {
                            visible: redisMouseArea.containsMouse
                            text: redisService ? 
                                  "Redis: " + redisService.connectionStatus + 
                                  "\\n" + redisService.redisHost + ":" + redisService.redisPort :
                                  "Redis: Not initialized"
                            delay: 500
                        }
                        
                        MouseArea {
                            id: redisMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (redisService) {
                                    if (redisService.connected) {
                                        redisService.disconnect()
                                    } else {
                                        redisService.reconnect()
                                    }
                                }
                            }
                        }
                        
                        // Pulsing animation when connected
                        SequentialAnimation {
                            running: redisService && redisService.connected
                            loops: Animation.Infinite
                            
                            PropertyAnimation {
                                target: parent
                                property: "opacity"
                                from: 1.0
                                to: 0.6
                                duration: 1000
                            }
                            
                            PropertyAnimation {
                                target: parent
                                property: "opacity"
                                from: 0.6
                                to: 1.0
                                duration: 1000
                            }
                        }
                    }
                }
                
                // Connection Status Details
                Column {
                    spacing: 2
                    
                    Text {
                        text: redisService ? redisService.connectionStatus : "Initializing..."
                        font.pixelSize: 12
                        color: redisService && redisService.connected ? "#4caf50" : "#f44336"
                        font.weight: Font.Bold
                    }
                    
                    Text {
                        text: redisService ? 
                              redisService.redisHost + ":" + redisService.redisPort : 
                              "Redis not configured"
                        font.pixelSize: 10
                        color: theme ? theme.textDim : "#aaaaaa"
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // System Status Indicators
                Row {
                    spacing: 8
                    
                    StatusIndicator {
                        status: redisService && redisService.statusData ? redisService.statusData.postgresConnected : false
                        label: "PostgreSQL"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: redisService && redisService.statusData ? redisService.statusData.workerRunning : false
                        label: "Worker"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: redisService && redisService.statusData ? redisService.statusData.alpacaApiActive : false
                        label: "Alpaca"
                        size: 12
                    }
                    
                    StatusIndicator {
                        status: redisService && redisService.statusData ? redisService.statusData.grokApiActive : false
                        label: "Grok"
                        size: 12
                    }
                }
                
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
                        visible: redisService && redisService.notificationsData && redisService.notificationsData.getUnreadCount() > 0
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
                            text: redisService && redisService.notificationsData ? 
                                  Math.min(redisService.notificationsData.getUnreadCount(), 99) : ""
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
                        marketModel: redisService ? redisService.marketData : null
                    }
                }
                
                // Charts View
                Item {
                    ModernChartView {
                        anchors.fill: parent
                        anchors.margins: 16
                        marketModel: redisService ? redisService.marketData : null
                        symbol: appSettings.lastSymbol
                        onSymbolChanged: appSettings.lastSymbol = symbol
                    }
                }
                
                // Portfolio View
                Item {
                    ModernPortfolioView {
                        anchors.fill: parent
                        anchors.margins: 16
                        portfolioModel: redisService ? redisService.portfolioData : null
                    }
                }
                
                // Orders View
                Item {
                    ModernOrdersView {
                        anchors.fill: parent
                        anchors.margins: 16
                        ordersModel: redisService ? redisService.ordersData : null
                    }
                }
                
                // Settings View
                Item {
                    ModernSettingsView {
                        anchors.fill: parent
                        anchors.margins: 16
                        settings: appSettings
                        dataService: root.redisService
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
            
            notificationsModel: redisService ? redisService.notificationsData : null
            
            Behavior on visible {
                NumberAnimation {
                    duration: theme ? theme.durMed : 200
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        // Redis Connection Error Overlay
        Rectangle {
            anchors.fill: parent
            color: "#aa000000"
            visible: !redisService || !redisService.connected
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from going through
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: 450
                height: 250
                radius: 12
                color: theme ? theme.bgElevated : "#2d2d2d"
                border.color: theme ? theme.danger : "#f44336"
                border.width: 2
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    
                    Text {
                        text: "🔌 Redis Verbindung"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: theme ? theme.danger : "#f44336"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: redisService ? 
                              "Status: " + redisService.connectionStatus + 
                              "\\nHost: " + redisService.redisHost + ":" + redisService.redisPort :
                              "Redis Service wird initialisiert..."
                        font.pixelSize: 16
                        color: theme ? theme.text : "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    Text {
                        text: "Bitte stellen Sie sicher, dass Redis läuft:\\nredis-server --port " + 
                              (redisService ? redisService.redisPort : 6380)
                        font.pixelSize: 12
                        color: theme ? theme.textDim : "#aaaaaa"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        
                        Rectangle {
                            width: 100
                            height: 32
                            radius: 16
                            color: "#2196f3"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "🔄 Retry"
                                font.pixelSize: 12
                                color: "#ffffff"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (redisService) {
                                        redisService.reconnect()
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: 100
                            height: 32
                            radius: 16
                            color: "#333333"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙️ Settings"
                                font.pixelSize: 12
                                color: "#ffffff"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    sideNav.currentIndex = 4 // Settings page
                                }
                            }
                        }
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
        sequence: "Ctrl+5"
        onActivated: sideNav.currentIndex = 4
    }
    
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: notificationDrawer.visible = !notificationDrawer.visible
    }
    
    Shortcut {
        sequence: "Ctrl+R"
        onActivated: {
            if (redisService) {
                redisService.reconnect()
            }
        }
    }
    
    Shortcut {
        sequence: "F5"
        onActivated: {
            if (redisService) {
                redisService.loadInitialData()
            }
        }
    }
}