import QtQuick 2.15
import QtQuick.Controls 2.15
import Frontend 1.0
import Frontend 1.0

Rectangle {
    id: root
    property int status: 0 // 0=down,1=ok
    property string label: ""
    property bool pulseOnChange: true
    height: 26
    radius: 13
    color: status === 1 ? Theme.success : Theme.danger
    border.color: status === 1 ? Theme.accent : Theme.danger
    border.width: 1
    implicitWidth: labelText.width + 26

    property int prevStatus: status

    onStatusChanged: {
        if (pulseOnChange && prevStatus !== status) {
            glowAnim.restart();
            prevStatus = status;
        }
    }

    Rectangle { // glow pulse
        id: glow
        anchors.centerIn: parent
        width: parent.width; height: parent.height
        radius: parent.radius
        color: status === 1 ? Theme.accent : Theme.danger
        opacity: 0
    }

    SequentialAnimation { id: glowAnim; loops: 1
        NumberAnimation { target: glow; property: "opacity"; from: 0; to: 0.55; duration: 180 }
        NumberAnimation { target: glow; property: "opacity"; from: 0.55; to: 0; duration: 420 }
    }

    Text { id: labelText; anchors.centerIn: parent; text: label; color: Theme.text; font.pixelSize: 12; font.bold: true }

    states: [
        State { name: "ok"; when: root.status === 1 },
        State { name: "down"; when: root.status !== 1 }
    ]

    transitions: [
        Transition {
            NumberAnimation { properties: "opacity"; duration: Theme.durMed }
            ColorAnimation { target: root; properties: "color"; duration: Theme.durMed }
        }
    ]
}
