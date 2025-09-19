import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    
    property bool status: false
    property string label: "Status"
    property int size: 16
    property color activeColor: "#4caf50"
    property color inactiveColor: "#f44336"
    
    width: indicator.width + labelText.width + 8
    height: Math.max(indicator.height, labelText.height)
    
    Rectangle {
        id: indicator
        width: root.size
        height: root.size
        radius: root.size / 2
        color: root.status ? root.activeColor : root.inactiveColor
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        
        // Pulsing animation for active status
        SequentialAnimation {
            running: root.status
            loops: Animation.Infinite
            
            PropertyAnimation {
                target: indicator
                property: "opacity"
                from: 1.0
                to: 0.6
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            
            PropertyAnimation {
                target: indicator
                property: "opacity"
                from: 0.6
                to: 1.0
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    Text {
        id: labelText
        text: root.label
        font.pixelSize: root.size - 2
        color: root.status ? "#ffffff" : "#aaaaaa"
        anchors.left: indicator.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }
    
    ToolTip {
        visible: mouseArea.containsMouse
        text: root.label + ": " + (root.status ? "Active" : "Inactive")
        delay: 1000
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}