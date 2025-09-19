import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string title: "Title"
    property real value: 0
    property string unit: "$"
    property real trend: 0
    property string icon: "💰"
    
    height: 100
    color: "#2d2d2d"
    radius: 12
    border.color: "#404040"
    border.width: 1
    
    // Hover effect
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "#ffffff"
        opacity: mouseArea.containsMouse ? 0.05 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: root.icon
                font.pixelSize: 20
            }
            
            Item { Layout.fillWidth: true }
            
            // Trend indicator
            Rectangle {
                visible: root.trend !== 0
                width: 16
                height: 16
                radius: 8
                color: root.trend > 0 ? "#4caf50" : "#f44336"
                
                Text {
                    anchors.centerIn: parent
                    text: root.trend > 0 ? "↑" : "↓"
                    font.pixelSize: 10
                    color: "white"
                }
            }
        }
        
        Text {
            text: root.title
            font.pixelSize: 12
            color: "#aaaaaa"
            Layout.fillWidth: true
        }
        
        Item { Layout.fillHeight: true }
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: root.unit + formatValue(root.value)
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
        }
        
        Text {
            visible: root.trend !== 0
            text: (root.trend > 0 ? "+" : "") + root.trend.toFixed(2) + "%"
            font.pixelSize: 10
            color: root.trend > 0 ? "#4caf50" : "#f44336"
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
    
    function formatValue(val) {
        if (root.unit === "$") {
            if (val >= 1000000) {
                return (val / 1000000).toFixed(1) + "M"
            } else if (val >= 1000) {
                return (val / 1000).toFixed(1) + "K"
            } else {
                return val.toFixed(2)
            }
        } else {
            return val.toFixed(0)
        }
    }
}