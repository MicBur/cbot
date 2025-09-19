import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    
    property alias title: titleText.text
    property alias content: contentLoader.sourceComponent
    property color cardColor: Theme.bgCard
    property bool glowEnabled: false
    property color glowColor: Theme.accent
    property real hoverScale: 1.02
    property bool interactive: true
    
    width: 300
    height: 200
    radius: Theme.radius
    color: cardColor
    
    // Glass effect layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.bgGlass
        opacity: mouseArea.containsMouse ? 0.3 : 0.15
        
        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast }
        }
    }
    
    // Border
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: mouseArea.containsMouse ? Theme.borderHover : Theme.border
        border.width: 1
        
        Behavior on border.color {
            ColorAnimation { duration: Theme.durFast }
        }
    }
    
    // Shadow
    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: mouseArea.containsMouse ? 8 : 4
        radius: mouseArea.containsMouse ? Theme.shadowRadius * 1.5 : Theme.shadowRadius
        color: "#80000000"
        samples: 17
        
        Behavior on verticalOffset {
            NumberAnimation { duration: Theme.durFast }
        }
        Behavior on radius {
            NumberAnimation { duration: Theme.durFast }
        }
    }
    
    // Glow effect
    Rectangle {
        id: glowRect
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        visible: glowEnabled
        
        layer.enabled: true
        layer.effect: Glow {
            radius: Theme.glowRadius
            color: glowColor
            samples: 32
            spread: 0.3
            
            SequentialAnimation on radius {
                running: glowEnabled
                loops: Animation.Infinite
                NumberAnimation { from: 15; to: 25; duration: Theme.durGlow; easing.type: Easing.InOutSine }
                NumberAnimation { from: 25; to: 15; duration: Theme.durGlow; easing.type: Easing.InOutSine }
            }
        }
    }
    
    // Content
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        
        Text {
            id: titleText
            color: Theme.text
            font.pixelSize: 18
            font.bold: true
            font.family: "Inter, Helvetica, Arial, sans-serif"
        }
        
        Loader {
            id: contentLoader
            width: parent.width
            height: parent.height - titleText.height - parent.spacing
        }
    }
    
    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: interactive
        
        onEntered: {
            if (interactive) {
                scaleAnimation.to = hoverScale;
                scaleAnimation.start();
            }
        }
        
        onExited: {
            if (interactive) {
                scaleAnimation.to = 1.0;
                scaleAnimation.start();
            }
        }
    }
    
    // Scale animation
    NumberAnimation {
        id: scaleAnimation
        target: root
        property: "scale"
        duration: Theme.durFast
        easing.type: Easing.OutCubic
    }
    
    // Transform origin
    transformOrigin: Item.Center
}