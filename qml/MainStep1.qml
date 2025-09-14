import QtQuick 2.15
import QtQuick.Controls 2.15
import Frontend 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    title: "Qt Trade Frontend - Step 1"
    color: Theme.bg

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 300
        color: Theme.bgElevated
        radius: 12
        border.color: Theme.accent
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "Qt Trade Frontend"
                color: Theme.accent
                font.pixelSize: 24
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Step 1: Base Interface ✓"
                color: Theme.text
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Theme System: ✓ Aktiv"
                color: Theme.success
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: 300
                height: 2
                color: Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Bereit für Komponent-Integration"
                color: Theme.textDim
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}