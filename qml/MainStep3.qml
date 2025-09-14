import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import Frontend 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    title: "Qt Trade Frontend"
    color: Theme.bg

    property bool redisConnected: poller.connected || false

    Rectangle { // top bar
        id: titleBar
        width: parent.width
        height: 60
        color: Theme.bg2
        z: 999

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.accent
            anchors.bottom: parent.bottom
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15

            Text {
                text: "QtTradeFrontend v0.1"
                color: Theme.text
                font.pixelSize: 20
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Redis: " + (redisConnected ? "✓ Verbunden" : "✗ Getrennt")
                color: redisConnected ? Theme.accent : Theme.error
                font.pixelSize: 14
            }
        }
    }

    // MainStep3: Sauberer Container ohne DropShadow-Effekte
    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: titleBar.height
        spacing: 0

        // Sidebar
        Rectangle {
            id: sidebar
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            color: Theme.bg2

            Rectangle {
                width: 1
                height: parent.height
                color: Theme.accent
                anchors.right: parent.right
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Text {
                    text: "Navigation"
                    color: Theme.text
                    font.pixelSize: 18
                    font.bold: true
                    width: parent.width
                }

                Button {
                    text: "Dashboard"
                    width: parent.width - 20
                    height: 40
                    enabled: false // TODO: Implement
                }
                
                Button {
                    text: "Märkte"
                    width: parent.width - 20
                    height: 40
                    enabled: false // TODO: Implement
                }
                
                Button {
                    text: "Portfolio"
                    width: parent.width - 20
                    height: 40
                    enabled: false // TODO: Implement
                }
                
                Button {
                    text: "Trades"
                    width: parent.width - 20
                    height: 40
                    enabled: false // TODO: Implement
                }
            }
        }

        // Content Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bg

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Step 3: Main Interface v0.2.0 ✓"
                    color: Theme.accent
                    font.pixelSize: 28
                    font.bold: true
                }

                Text {
                    text: "Theme System: ✓ Aktiv"
                    color: Theme.success
                    font.pixelSize: 16
                }

                Text {
                    text: "Import Konflikte: ✓ Gelöst"
                    color: Theme.success
                    font.pixelSize: 16
                }

                Text {
                    text: "DropShadow Effekte: ⚠ Entfernt"
                    color: Theme.warning
                    font.pixelSize: 16
                }

                Text {
                    text: "Navigation: ⚠ Placeholder"
                    color: Theme.warning
                    font.pixelSize: 16
                }

                Button {
                    text: "Test Button"
                    width: 200
                    height: 40
                    onClicked: {
                        console.log("MainStep3 Test Button clicked")
                    }
                }
            }
        }
    }

    // Status Footer
    Rectangle {
        width: parent.width
        height: 30
        color: Theme.bg2
        anchors.bottom: parent.bottom

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.accent
            anchors.top: parent.top
        }

        Text {
            text: "MainStep3 v0.2.0: Basis Interface ohne Effects | Redis Port: --redis-port 6380"
            color: Theme.text
            font.pixelSize: 12
            anchors.centerIn: parent
        }
    }

    // TODO: Data Poller mock - statische Version für MainStep3
    QtObject {
        id: poller
        property bool connected: true  // Mock: einfach immer verbunden
    }
}