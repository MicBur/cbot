import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

Rectangle {
    id: root
    property int status: 0 // 0=down,1=ok
    property string label: ""
    property bool pulseOnChange: true
    height: 28
    radius: 14
    color: "transparent"
    implicitWidth: Math.max(80, labelText.width + 32)

    property int prevStatus: status

    onStatusChanged: {
        if (pulseOnChange && prevStatus !== status) {
            glowAnim.restart();
            scaleAnim.restart();
            prevStatus = status;
        }
    }

    // Background with gradient
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        
        gradient: Gradient {
            GradientStop { 
                position: 0.0
                color: status === 1 ? Qt.lighter(Theme.success, 1.2) : Qt.lighter(Theme.danger, 1.2)
            }
            GradientStop { 
                position: 1.0
                color: status === 1 ? Theme.success : Theme.danger
            }
        }
        
        opacity: 0.9
    }

    // Glass effect overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.bgGlass
        opacity: 0.3
    }

    // Border
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: status === 1 ? Theme.accent : Theme.danger
        border.width: 1
        opacity: 0.8
    }

    // Glow effect
    Rectangle {
        id: glowRect
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        
        layer.enabled: true
        layer.effect: Glow {
            id: glowEffect
            radius: 0
            color: status === 1 ? Theme.successGlow : Theme.dangerGlow
            samples: 24
            spread: 0.5
        }
    }

    // Pulse animation
    SequentialAnimation { 
        id: glowAnim
        loops: 2
        NumberAnimation { target: glowEffect; property: "radius"; from: 0; to: 15; duration: 200; easing.type: Easing.OutQuad }
        NumberAnimation { target: glowEffect; property: "radius"; from: 15; to: 0; duration: 400; easing.type: Easing.InQuad }
    }

    // Scale animation
    SequentialAnimation {
        id: scaleAnim
        NumberAnimation { target: root; property: "scale"; from: 1; to: 1.1; duration: 100; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "scale"; from: 1.1; to: 1; duration: 200; easing.type: Easing.InBack }
    }

    // Status icon
    Text {
        id: statusIcon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        text: status === 1 ? "●" : "○"
        color: Theme.text
        font.pixelSize: 12
        
        SequentialAnimation on opacity {
            running: status !== 1
            loops: Animation.Infinite
            NumberAnimation { from: 0.3; to: 1; duration: 500 }
            NumberAnimation { from: 1; to: 0.3; duration: 500 }
        }
    }

    // Label text
    Text { 
        id: labelText
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 8
        text: label
        color: Theme.text
        font.pixelSize: 12
        font.bold: true
        font.family: "Inter, Helvetica, Arial, sans-serif"
    }

    // Hover effect
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            hoverAnim.to = 1.05
            hoverAnim.start()
        }
        
        onExited: {
            hoverAnim.to = 1.0
            hoverAnim.start()
        }
    }

    NumberAnimation {
        id: hoverAnim
        target: root
        property: "scale"
        duration: Theme.durFast
        easing.type: Easing.OutCubic
    }

    states: [
        State { name: "ok"; when: root.status === 1 },
        State { name: "down"; when: root.status !== 1 }
    ]

    transitions: [
        Transition {
            NumberAnimation { properties: "opacity"; duration: Theme.durMed }
            ColorAnimation { properties: "color"; duration: Theme.durMed }
        }
    ]
}
