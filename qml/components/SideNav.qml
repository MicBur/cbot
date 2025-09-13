import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Frontend 1.0

Rectangle {
    id: nav
    color: Theme.bgElevated
    property int currentIndex: 0

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 8
        Repeater {
            model: ["Dashboard", "Charts", "Portfolio", "Trades", "Settings"]
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 60
                color: index === nav.currentIndex ? Theme.accentAlt : "transparent"
                border.width: index === nav.currentIndex ? 2 : 1
                border.color: index === nav.currentIndex ? Theme.accent : Theme.bgElevated
                radius: 6
                layer.enabled: index === nav.currentIndex
                layer.smooth: true
                Rectangle { // inner glow pulse overlay
                    id: glow
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 0
                    opacity: 0.0
                }
                SequentialAnimation on opacity { running: false }
                SequentialAnimation {
                    id: pulse
                    running: index === nav.currentIndex
                    loops: Animation.Infinite
                    PropertyAnimation { target: glow; property: "opacity"; from: 0.0; to: 0.5; duration: 600; easing.type: Easing.InOutQuad }
                    PropertyAnimation { target: glow; property: "opacity"; from: 0.5; to: 0.0; duration: 600; easing.type: Easing.InOutQuad }
                }
                Text { anchors.centerIn: parent; text: modelData; color: Theme.text; font.pixelSize: 12; font.bold: index===nav.currentIndex }
                MouseArea {
                    anchors.fill: parent
                    onClicked: nav.currentIndex = index
                }
                Behavior on color { ColorAnimation { duration: Theme.durMed }}
                Behavior on border.width { NumberAnimation { duration: 240 }}
            }
        }
        Rectangle { Layout.fillHeight: true; Layout.fillWidth: true; color: "transparent" }
    }
}
