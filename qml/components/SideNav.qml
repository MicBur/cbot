import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

Rectangle {
    id: nav
    color: Theme.bgElevated
    property int currentIndex: 0

    // Glass effect
    Rectangle {
        anchors.fill: parent
        color: Theme.bgGlass
        border.color: Theme.border
        border.width: 1
    }

    ListModel {
        id: navModel
        ListElement { icon: "🏠"; label: "Dashboard" }
        ListElement { icon: "📈"; label: "Signals" }
        ListElement { icon: "💼"; label: "Portfolio" }
        ListElement { icon: "🤖"; label: "AI Analysis" }
        ListElement { icon: "📝"; label: "Orders" }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 2
        anchors.margins: 8
        
        Repeater {
            model: navModel
            delegate: Rectangle {
                id: navItem
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Theme.radius
                color: index === nav.currentIndex ? Theme.accent : (mouseArea.containsMouse ? Theme.bgCard : "transparent")
                
                Behavior on color {
                    ColorAnimation { duration: Theme.durFast }
                }

                // Glow effect for active item
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    visible: index === nav.currentIndex
                    
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 15
                        color: Theme.accentGlow
                        samples: 24
                        spread: 0.4
                        
                        SequentialAnimation on radius {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { from: 12; to: 18; duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 18; to: 12; duration: 1500; easing.type: Easing.InOutSine }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        id: iconText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: model.icon
                        font.pixelSize: 28
                        color: index === nav.currentIndex ? Theme.bg : Theme.text
                        
                        transform: Scale {
                            id: iconScale
                            origin.x: iconText.width / 2
                            origin.y: iconText.height / 2
                        }
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: model.label
                        font.pixelSize: 10
                        color: index === nav.currentIndex ? Theme.bg : Theme.textDim
                        font.bold: index === nav.currentIndex
                        visible: navItem.width > 80
                        opacity: navItem.width > 100 ? 1 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.durFast }
                        }
                    }
                }

                // Hover scale effect
                transform: Scale {
                    origin.x: navItem.width / 2
                    origin.y: navItem.height / 2
                    xScale: mouseArea.containsMouse ? 1.05 : 1
                    yScale: mouseArea.containsMouse ? 1.05 : 1
                    
                    Behavior on xScale {
                        NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
                    }
                    Behavior on yScale {
                        NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        nav.currentIndex = index
                        bounceAnimation.start()
                    }
                }
                
                // Bounce animation
                SequentialAnimation {
                    id: bounceAnimation
                    NumberAnimation { target: iconScale; property: "xScale"; from: 1; to: 1.2; duration: 100; easing.type: Easing.OutQuad }
                    NumberAnimation { target: iconScale; property: "xScale"; from: 1.2; to: 1; duration: 100; easing.type: Easing.InQuad }
                    NumberAnimation { target: iconScale; property: "yScale"; from: 1; to: 1.2; duration: 100; easing.type: Easing.OutQuad }
                    NumberAnimation { target: iconScale; property: "yScale"; from: 1.2; to: 1; duration: 100; easing.type: Easing.InQuad }
                }
                
                // Selection indicator bar
                Rectangle {
                    width: 3
                    height: parent.height * 0.6
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: -4
                    radius: 1.5
                    color: Theme.accent
                    visible: index === nav.currentIndex
                    opacity: visible ? 1 : 0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durFast }
                    }
                    
                    Behavior on height {
                        NumberAnimation { duration: Theme.durMed; easing.type: Easing.OutBack }
                    }
                }
            }
        }
        
        Rectangle { Layout.fillHeight: true; Layout.fillWidth: true; color: "transparent" }
    }
}
