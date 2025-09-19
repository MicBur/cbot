import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var settings: null
    property var dataService: null
    
    color: "#1e1e1e"
    radius: 8
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        clip: true
        
        ColumnLayout {
            width: parent.width - 32
            spacing: 24
            
            // Header
            Text {
                text: "⚙️ Settings"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#ffffff"
                Layout.fillWidth: true
            }
            
            // Connection Settings
            GroupBox {
                title: "Connection Settings"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#2d2d2d"
                    radius: 8
                    border.color: "#404040"
                    border.width: 1
                }
                
                label: Text {
                    text: parent.title
                    color: "#ffffff"
                    font.weight: Font.Bold
                    padding: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Redis Host:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 100
                        }
                        
                        TextField {
                            id: hostField
                            text: root.settings ? root.settings.redisHost : "127.0.0.1"
                            Layout.fillWidth: true
                            
                            background: Rectangle {
                                color: "#333333"
                                border.color: parent.activeFocus ? "#2196f3" : "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            color: "#ffffff"
                            
                            onEditingFinished: {
                                if (root.settings) {
                                    root.settings.redisHost = text
                                }
                                if (root.dataService) {
                                    root.dataService.redisHost = text
                                }
                            }
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Redis Port:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 100
                        }
                        
                        SpinBox {
                            id: portSpinBox
                            from: 1
                            to: 65535
                            value: root.settings ? root.settings.redisPort : 6380
                            
                            background: Rectangle {
                                color: "#333333"
                                border.color: parent.activeFocus ? "#2196f3" : "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: TextInput {
                                text: portSpinBox.textFromValue(portSpinBox.value, portSpinBox.locale)
                                font: portSpinBox.font
                                color: "#ffffff"
                                selectionColor: "#2196f3"
                                selectedTextColor: "#ffffff"
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !portSpinBox.editable
                                validator: portSpinBox.validator
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                            }
                            
                            onValueChanged: {
                                if (root.settings) {
                                    root.settings.redisPort = value
                                }
                                if (root.dataService) {
                                    root.dataService.redisPort = value
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Password:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 100
                        }
                        
                        TextField {
                            id: passwordField
                            text: root.settings ? root.settings.redisPassword : ""
                            echoMode: TextInput.Password
                            Layout.fillWidth: true
                            
                            background: Rectangle {
                                color: "#333333"
                                border.color: parent.activeFocus ? "#2196f3" : "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            color: "#ffffff"
                            
                            onEditingFinished: {
                                if (root.settings) {
                                    root.settings.redisPassword = text
                                }
                                if (root.dataService) {
                                    root.dataService.redisPassword = text
                                }
                            }
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Rectangle {
                            width: 80
                            height: 32
                            radius: 16
                            color: "#2196f3"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Test Connection"
                                font.pixelSize: 10
                                color: "#ffffff"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Testing connection...")
                                    if (root.dataService) {
                                        root.dataService.loadInitialData()
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: root.dataService ? ("Status: " + root.dataService.connectionStatus) : "Status: Unknown"
                            font.pixelSize: 12
                            color: root.dataService && root.dataService.connected ? "#4caf50" : "#f44336"
                        }
                    }
                }
            }
            
            // UI Settings
            GroupBox {
                title: "User Interface"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#2d2d2d"
                    radius: 8
                    border.color: "#404040"
                    border.width: 1
                }
                
                label: Text {
                    text: parent.title
                    color: "#ffffff"
                    font.weight: Font.Bold
                    padding: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Theme:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 100
                        }
                        
                        ComboBox {
                            id: themeCombo
                            model: ["Dark", "Light", "Auto"]
                            currentIndex: 0
                            Layout.preferredWidth: 120
                            
                            background: Rectangle {
                                color: "#333333"
                                border.color: parent.activeFocus ? "#2196f3" : "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: themeCombo.displayText
                                font: themeCombo.font
                                color: "#ffffff"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                            }
                            
                            onCurrentTextChanged: {
                                if (root.settings) {
                                    root.settings.theme = currentText.toLowerCase()
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Notifications:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 100
                        }
                        
                        Switch {
                            id: notificationsSwitch
                            checked: root.settings ? root.settings.notifications : true
                            
                            onCheckedChanged: {
                                if (root.settings) {
                                    root.settings.notifications = checked
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
            }
            
            // Trading Settings
            GroupBox {
                title: "Trading"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#2d2d2d"
                    radius: 8
                    border.color: "#404040"
                    border.width: 1
                }
                
                label: Text {
                    text: parent.title
                    color: "#ffffff"
                    font.weight: Font.Bold
                    padding: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Default Symbol:"
                            color: "#aaaaaa"
                            Layout.preferredWidth: 120
                        }
                        
                        TextField {
                            text: root.settings ? root.settings.lastSymbol : "AAPL"
                            Layout.preferredWidth: 100
                            
                            background: Rectangle {
                                color: "#333333"
                                border.color: parent.activeFocus ? "#2196f3" : "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            color: "#ffffff"
                            
                            onEditingFinished: {
                                if (root.settings) {
                                    root.settings.lastSymbol = text
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    Text {
                        text: "⚠️ Trading functionality is currently in development"
                        font.pixelSize: 12
                        color: "#ff9800"
                        Layout.fillWidth: true
                    }
                }
            }
            
            // About Section
            GroupBox {
                title: "About"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: "#2d2d2d"
                    radius: 8
                    border.color: "#404040"
                    border.width: 1
                }
                
                label: Text {
                    text: parent.title
                    color: "#ffffff"
                    font.weight: Font.Bold
                    padding: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    Text {
                        text: "QtTrade Frontend - Pure QML"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: "Version: 1.0.0"
                        font.pixelSize: 12
                        color: "#aaaaaa"
                    }
                    
                    Text {
                        text: "Built with Qt " + Qt.version
                        font.pixelSize: 12
                        color: "#aaaaaa"
                    }
                    
                    Text {
                        text: "A modern trading frontend built entirely in QML with WebSocket connectivity."
                        font.pixelSize: 12
                        color: "#cccccc"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Rectangle {
                            width: 100
                            height: 32
                            radius: 16
                            color: "#2196f3"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "📋 Logs"
                                font.pixelSize: 12
                                color: "#ffffff"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Show application logs")
                                    // TODO: Show logs dialog
                                }
                            }
                        }
                        
                        Rectangle {
                            width: 100
                            height: 32
                            radius: 16
                            color: "#4caf50"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "🔄 Reset"
                                font.pixelSize: 12
                                color: "#ffffff"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Reset settings to defaults")
                                    resetToDefaults()
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
            }
            
            // Spacer at bottom
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
            }
        }
    }
    
    function resetToDefaults() {
        if (root.settings) {
            root.settings.redisHost = "127.0.0.1"
            root.settings.redisPort = 6380
            root.settings.redisPassword = ""
            root.settings.theme = "dark"
            root.settings.notifications = true
            root.settings.lastSymbol = "AAPL"
            
            // Update UI elements
            hostField.text = "127.0.0.1"
            portSpinBox.value = 6380
            passwordField.text = ""
            themeCombo.currentIndex = 0
            notificationsSwitch.checked = true
        }
        
        console.log("Settings reset to defaults")
    }
}