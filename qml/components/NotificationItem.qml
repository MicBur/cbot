import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string title: ""
    property string message: ""
    property string timestamp: ""
    property string type: "info"
    property bool read: false
    
    signal markAsRead()
    
    height: contentColumn.height + 24
    color: root.read ? "#2a2a2a" : "#333333"
    radius: 8
    border.color: root.read ? "transparent" : getTypeColor(root.type)
    border.width: 2
    
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
    
    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8
        
        RowLayout {
            width: parent.width
            
            Text {
                text: getTypeIcon(root.type)
                font.pixelSize: 16
            }
            
            Text {
                text: root.title
                font.pixelSize: 14
                font.weight: Font.Bold
                color: "#ffffff"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Rectangle {
                visible: !root.read
                width: 8
                height: 8
                radius: 4
                color: "#2196f3"
            }
        }
        
        Text {
            text: root.message
            font.pixelSize: 12
            color: "#cccccc"
            width: parent.width
            wrapMode: Text.WordWrap
        }
        
        Text {
            text: formatTimestamp(root.timestamp)
            font.pixelSize: 10
            color: "#888888"
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (!root.read) {
                root.markAsRead()
            }
        }
    }
    
    function getTypeColor(type) {
        switch(type) {
            case "error": return "#f44336"
            case "warning": return "#ff9800"
            case "success": return "#4caf50"
            default: return "#2196f3"
        }
    }
    
    function getTypeIcon(type) {
        switch(type) {
            case "error": return "❌"
            case "warning": return "⚠️"
            case "success": return "✅"
            default: return "ℹ️"
        }
    }
    
    function formatTimestamp(timestamp) {
        if (!timestamp) return ""
        
        let date = new Date(timestamp)
        let now = new Date()
        let diff = now - date
        
        if (diff < 60000) { // Less than 1 minute
            return "Just now"
        } else if (diff < 3600000) { // Less than 1 hour
            return Math.floor(diff / 60000) + "m ago"
        } else if (diff < 86400000) { // Less than 1 day
            return Math.floor(diff / 3600000) + "h ago"
        } else {
            return date.toLocaleDateString()
        }
    }
}