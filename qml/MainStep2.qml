import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import Frontend 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    title: "Qt Trade Frontend - Step 2"
    color: Theme.bg

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Step 2: Base Main Interface ✓"
                color: Theme.accent
                font.pixelSize: 28
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Theme System: ✓ Aktiv"
                color: Theme.success
                font.pixelSize: 18
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Import Konflikt: Gelöst ✓"
                color: Theme.success
                font.pixelSize: 18
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: 300
                height: 2
                color: Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Nächste Stufe: Custom Components"
                color: Theme.textDim
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}