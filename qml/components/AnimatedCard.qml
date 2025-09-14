import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import "../" as App

/**
 * Animated card component with hover effects and smooth transitions
 */
Rectangle {
    id: root
    
    // Properties
    property alias title: titleText.text
    property alias content: contentLoader.sourceComponent
    property color cardColor: Theme.surface
    property color hoverColor: Theme.surfaceElevated
    property int animationDuration: Theme.durationNormal
    property bool interactive: true
    property bool elevated: true
    property int elevation: 1
    
    // Signals
    signal clicked()
    signal entered()
    signal exited()
    
    // Default size
    implicitWidth: 300
    implicitHeight: 200
    
    // Appearance
    color: mouseArea.containsMouse && interactive ? hoverColor : cardColor
    radius: Theme.radiusMedium
    
    // Smooth color transitions
    Behavior on color {
        ColorAnimation { duration: animationDuration }
    }
    
    // Scale animation on hover
    transform: Scale {
        id: scaleTransform
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse && interactive ? 1.02 : 1.0)
        yScale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse && interactive ? 1.02 : 1.0)
        
        Behavior on xScale {
            NumberAnimation { 
                duration: animationDuration 
                easing.type: Theme.easingStandard
            }
        }
        Behavior on yScale {
            NumberAnimation { 
                duration: animationDuration 
                easing.type: Theme.easingStandard
            }
        }
    }
    
    // Shadow effect
    layer.enabled: elevated
    layer.effect: DropShadow {
        transparentBorder: true
        color: "#40000000"
        radius: mouseArea.containsMouse ? 16 : (elevation * 4)
        samples: radius * 2 + 1
        horizontalOffset: 0
        verticalOffset: mouseArea.containsMouse ? 6 : (elevation * 2)
        
        Behavior on radius {
            NumberAnimation { duration: animationDuration }
        }
        Behavior on verticalOffset {
            NumberAnimation { duration: animationDuration }
        }
    }
    
    // Glow effect on hover
    Rectangle {
        id: glowEffect
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Theme.primary
        border.width: 2
        opacity: 0
        
        states: State {
            name: "hovered"
            when: mouseArea.containsMouse && interactive
            PropertyChanges { target: glowEffect; opacity: 0.3 }
        }
        
        transitions: Transition {
            NumberAnimation { 
                property: "opacity"
                duration: animationDuration
                easing.type: Theme.easingStandard
            }
        }
    }
    
    // Content layout
    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacing4
        spacing: Theme.spacing3
        
        // Title bar
        Rectangle {
            width: parent.width
            height: 40
            color: "transparent"
            
            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font: Theme.h4
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            
            // Optional close button
            Rectangle {
                id: closeButton
                width: 24
                height: 24
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                radius: 12
                color: closeMouseArea.containsMouse ? Theme.danger : "transparent"
                visible: interactive
                
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 18
                    color: Theme.textPrimary
                }
                
                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.visible = false
                }
                
                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }
        
        // Separator line with animation
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.textDisabled
            opacity: 0.2
            
            // Animated width on hover
            Rectangle {
                height: parent.height
                width: mouseArea.containsMouse ? parent.width : 0
                color: Theme.primary
                
                Behavior on width {
                    NumberAnimation { 
                        duration: animationDuration
                        easing.type: Theme.easingDecelerate
                    }
                }
            }
        }
        
        // Content area
        Loader {
            id: contentLoader
            width: parent.width
            height: parent.height - y - Theme.spacing3
        }
    }
    
    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: interactive
        
        onClicked: {
            if (interactive) {
                clickAnimation.start()
                root.clicked()
            }
        }
        
        onEntered: {
            if (interactive) {
                root.entered()
            }
        }
        
        onExited: {
            if (interactive) {
                root.exited()
            }
        }
    }
    
    // Click ripple effect
    Rectangle {
        id: ripple
        anchors.centerIn: parent
        width: 0
        height: width
        radius: width / 2
        color: Theme.primary
        opacity: 0
        
        ParallelAnimation {
            id: clickAnimation
            
            NumberAnimation {
                target: ripple
                property: "width"
                from: 0
                to: Math.max(root.width, root.height) * 2
                duration: Theme.durationSlow
                easing.type: Theme.easingDecelerate
            }
            
            SequentialAnimation {
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    from: 0
                    to: 0.3
                    duration: Theme.durationFast
                }
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    to: 0
                    duration: Theme.durationNormal
                }
            }
        }
    }
}