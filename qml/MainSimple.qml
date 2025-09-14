import QtQuick 2.15
import QtQuick.Controls 2.15
import Frontend 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    title: "Qt Trade Frontend - Test"
    
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        
        Text {
            anchors.centerIn: parent
            text: "Qt Trade Frontend läuft!"
            color: Theme.text
            font.pixelSize: 24
        }
        
        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 50
            text: "Theme System: ✓ Aktiv"
            color: Theme.accent
            font.pixelSize: 16
        }
    }
}