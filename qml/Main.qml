import QtQuick 2.15
// Primärer Import für Effekte in Qt 6 (stellt DropShadow u.a. bereit)
import QtQuick.Effects
// Fallback (ältere Beispiele / Kompatibilität) – falls QtQuick.Effects nicht verfügbar ist
import Qt5Compat.GraphicalEffects
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

    property bool redisConnected: poller.connected

    Rectangle { // top bar
        id: topBar
        anchors.top: parent.top
        height: 48
        width: parent.width
        color: Theme.bgElevated
        RowLayout {
            anchors.fill: parent
            spacing: 16
            MyLabel { text: "QtTrade"; font.pixelSize: 20; color: Theme.accent }
            Rectangle { Layout.fillWidth: true; color: "transparent" }
            // Ersetze einzelne Redis Badge durch mehrere Status Badges
            RowLayout {
                spacing: 6
                StatusBadge { status: poller.connected ? 1 : 0; label: poller.connected ? "Redis" : "No Redis" }
                StatusBadge { status: statusModel && statusModel.postgresConnected ? 1 : 0; label: statusModel && statusModel.postgresConnected ? "Postgres" : "PG Down" }
                StatusBadge { status: statusModel && statusModel.workerRunning ? 1 : 0; label: statusModel && statusModel.workerRunning ? "Worker" : "Worker" }
                StatusBadge { status: statusModel && statusModel.alpacaApiActive ? 1 : 0; label: statusModel && statusModel.alpacaApiActive ? "Alpaca" : "Alpaca" }
                StatusBadge { status: statusModel && statusModel.grokApiActive ? 1 : 0; label: statusModel && statusModel.grokApiActive ? "Grok" : "Grok" }
            }
            MyLabel { text: Qt.formatTime(new Date(), "HH:mm:ss"); color: Theme.text; font.family: "Consolas" }
            Timer { interval: 1000; running: true; repeat: true; onTriggered: topBar.forceLayout() }
        }
    }

    SideNav {
        id: side
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        width: 70
        onCurrentIndexChanged: stackView.currentIndex = currentIndex
    }

    // Simple Stack of pages (placeholder)
    StackLayout {
        id: stackView
        anchors.top: topBar.bottom
        anchors.left: side.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: side.currentIndex

        // Dashboard Page
        Item {
            ColumnLayout { anchors.fill: parent; spacing: 0
                MyLabel { text: "Market"; color: Theme.text; font.bold: true; font.pixelSize: 18 }
                MarketList { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }

        // Charts page replaced with CandleChart component
        Item {
            ColumnLayout { anchors.fill: parent; spacing: 0
                MyLabel { text: "Charts"; color: Theme.text; font.bold: true; font.pixelSize: 18 }
                CandleChart { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }
        // Portfolio view
        Item {
            ColumnLayout { anchors.fill: parent; spacing: 0
                MyLabel { text: "Portfolio"; color: Theme.text; font.bold: true; font.pixelSize: 18 }
                ListView { Layout.fillWidth: true; Layout.fillHeight: true; model: portfolioModel; clip: true
                    delegate: Rectangle {
                        width: ListView.view.width; height: 40; color: index % 2 === 0 ? Theme.bgElevated : Theme.bg
                        RowLayout { anchors.fill: parent; spacing: 12
                            Text { text: ticker; width: 90; color: Theme.text }
                            Text { text: Number(qty).toFixed(2); width: 80; color: Theme.text }
                            Text { text: Number(avgPrice).toFixed(2); width: 90; color: Theme.text }
                            Text { text: side; width: 60; color: side === "short" ? Theme.danger : Theme.success }
                            Rectangle { Layout.fillWidth: true; color: "transparent" }
                        }
                    }
                }
            }
        }
        // Orders view
        Item {
            ColumnLayout { anchors.fill: parent; spacing: 0
                MyLabel { text: "Orders"; color: Theme.text; font.bold: true; font.pixelSize: 18 }
                ListView { Layout.fillWidth: true; Layout.fillHeight: true; model: ordersModel; clip: true
                    delegate: Rectangle {
                        width: ListView.view.width; height: 42; color: index % 2 === 0 ? Theme.bgElevated : Theme.bg
                        RowLayout { anchors.fill: parent; spacing: 10
                            Text { text: ticker; width: 80; color: Theme.text }
                            Text { text: side; width: 50; color: side === "buy" ? Theme.success : Theme.danger }
                            Text { text: Number(price).toFixed(2); width: 80; color: Theme.text }
                            Text { text: status; width: 90; color: status === "filled" ? Theme.success : (status === "cancelled" ? Theme.danger : Theme.textDim) }
                            Text { text: timestamp; width: 160; color: Theme.textDim; font.pixelSize: 11 }
                            Rectangle { Layout.fillWidth: true; color: "transparent" }
                        }
                    }
                }
            }
        }
        // Settings placeholder (will hold notifications button)
        Item { Text { anchors.centerIn: parent; text: "Settings (coming)"; color: Theme.text } }
    }

    // Notification Drawer
    Rectangle {
        id: notificationDrawer
        width: 360
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: Theme.bgElevated
        border.color: Theme.accentAlt
        border.width: 1
        radius: 0
        visible: drawerState === 1
        opacity: drawerState === 1 ? 1 : 0
        property int drawerState: 0 // 0 hidden,1 shown
        Behavior on opacity { NumberAnimation { duration: Theme.durMed } }
        ColumnLayout { anchors.fill: parent; anchors.margins: 6; spacing: 4
            RowLayout {
                MyLabel { text: "Notifications"; color: Theme.accent; font.bold: true; font.pixelSize: 18 }
                Rectangle { Layout.fillWidth: true; color: "transparent" }
                Button { text: "×"; onClicked: notificationDrawer.drawerState = 0 }
            }
            ListView { Layout.fillWidth: true; Layout.fillHeight: true; model: notificationsModel; clip: true
                delegate: Rectangle {
                    width: ListView.view.width; implicitHeight: 72
                    color: read ? Theme.bg : Theme.bgElevated
                    border.width: 1; border.color: Theme.accentAlt
                    Column {
                        anchors.fill: parent; anchors.margins: 6
                        Text { text: title; color: Theme.text; font.bold: true; font.pixelSize: 14 }
                        Text { text: message; color: Theme.textDim; wrapMode: Text.Wrap }
                        Row { spacing: 8
                            Text { text: timestamp; color: Theme.textDim; font.pixelSize: 10 }
                            Text { text: type; color: type === "error" ? Theme.danger : (type === "warning" ? Theme.warning : (type === "success" ? Theme.success : Theme.textDim)); font.pixelSize: 10 }
                            Rectangle { width: 1; height: 10; color: "#333" }
                            MouseArea { anchors.fill: parent; onClicked: notificationsModel.markRead(index) }
                        }
                    }
                }
            }
        }
    }

    // Toggle Button (floating)
    Rectangle {
        id: notifToggle
        width: 42; height: 42; radius: 21
        color: notificationDrawer.drawerState === 1 ? Theme.accent : Theme.accentAlt
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 18
        border.color: Theme.accent; border.width: 1
        Text { anchors.centerIn: parent; text: notificationDrawer.drawerState === 1 ? "×" : "🔔"; color: Theme.bg; font.pixelSize: 20 }
        MouseArea { anchors.fill: parent; onClicked: notificationDrawer.drawerState = notificationDrawer.drawerState === 1 ? 0 : 1 }
        Behavior on color { ColorAnimation { duration: Theme.durMed } }
        layer.enabled: false
        layer.effect: DropShadow {
            radius: 16
            samples: 24
            horizontalOffset: 0
            verticalOffset: 4
            color: "#80000000"
        }
    }

    // Error Overlay (Redis Down or System Down) - simple initial version
    Rectangle {
        id: errorOverlay
        anchors.fill: parent
        color: poller.connected ? "transparent" : "#aa000000"
        visible: !poller.connected
        Column {
            anchors.centerIn: parent
            spacing: 12
            Rectangle { width: 300; height: 140; radius: 12; color: Theme.bgElevated; border.color: Theme.danger; border.width: 1
                Column { anchors.fill: parent; anchors.margins: 16; spacing: 8
                    Text { text: "Verbindung verloren"; color: Theme.danger; font.bold: true; font.pixelSize: 20 }
                    Text { text: "Redis nicht erreichbar. Reconnect versucht automatisch."; color: Theme.textDim; wrapMode: Text.WordWrap }
                }
            }
        }
        Behavior on color { ColorAnimation { duration: 400 } }
    }
}
