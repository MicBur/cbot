import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property int currentIndex: 0
    property var navItems: [
        { icon: "📊", label: "Market", tooltip: "Market Dashboard" },
        { icon: "📈", label: "Charts", tooltip: "Price Charts" },
        { icon: "💼", label: "Portfolio", tooltip: "Portfolio Overview" },
        { icon: "📋", label: "Orders", tooltip: "Order History" },
        { icon: "⚙️", label: "Settings", tooltip: "Application Settings" }
    ]
    
    color: "#1a1a1a"
    border.color: "#333333"
    border.width: 1
    
    Column {
        anchors.fill: parent
        anchors.topMargin: 16
        spacing: 8
        
        Repeater {
            model: root.navItems
            
            Rectangle {
                width: root.width - 16
                height: 56
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 8
                
                color: index === root.currentIndex ? "#2196f3" : (mouseArea.containsMouse ? "#333333" : "transparent")
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        text: modelData.icon
                        font.pixelSize: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: modelData.label
                        font.pixelSize: 10
                        color: index === root.currentIndex ? "#ffffff" : "#aaaaaa"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.currentIndex = index
                }
                
                ToolTip {
                    visible: mouseArea.containsMouse && index !== root.currentIndex
                    text: modelData.tooltip
                    delay: 500
                }
                
                // Selection indicator
                Rectangle {
                    visible: index === root.currentIndex
                    width: 3
                    height: parent.height - 8
                    color: "#64b5f6"
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.5
                }
            }
        }
        
        // Spacer
        Item {
            width: 1
            height: 32
        }
        
        // Version info at bottom
        Text {
            text: "v1.0.0"
            font.pixelSize: 8
            color: "#666666"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}