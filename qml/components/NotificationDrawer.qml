import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var notificationsModel: null
    
    color: "#1e1e1e"
    border.color: "#404040"
    border.width: 1
    
    // Slide in/out animation
    transform: Translate {
        id: slideTransform
        x: root.visible ? 0 : root.width
        
        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "🔔 Notifications"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Rectangle {
                visible: root.notificationsModel && root.notificationsModel.getUnreadCount() > 0
                width: 24
                height: 18
                radius: 9
                color: "#f44336"
                
                Text {
                    anchors.centerIn: parent
                    text: root.notificationsModel ? root.notificationsModel.getUnreadCount() : ""
                    font.pixelSize: 10
                    color: "white"
                    font.weight: Font.Bold
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Mark all as read button
            Rectangle {
                width: 80
                height: 28
                radius: 14
                color: "#2196f3"
                opacity: markAllMouseArea.containsMouse ? 1 : 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "Mark All"
                    font.pixelSize: 10
                    color: "white"
                }
                
                MouseArea {
                    id: markAllMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.notificationsModel) {
                            root.notificationsModel.markAllRead()
                        }
                    }
                }
            }
            
            // Close button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "#333333"
                
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 14
                    color: "#ffffff"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.visible = false
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#404040"
        }
        
        // Notifications List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: notificationsList
                model: root.notificationsModel
                spacing: 8
                
                delegate: NotificationItem {
                    width: notificationsList.width
                    title: model.title || ""
                    message: model.message || ""
                    timestamp: model.timestamp || ""
                    type: model.type || "info"
                    read: model.read || false
                    
                    onMarkAsRead: {
                        if (root.notificationsModel) {
                            root.notificationsModel.markRead(index)
                        }
                    }
                }
                
                // Empty state
                Item {
                    visible: notificationsList.count === 0
                    anchors.centerIn: parent
                    width: 250
                    height: 200
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        
                        Text {
                            text: "🔕"
                            font.pixelSize: 48
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "No notifications"
                            font.pixelSize: 16
                            color: "#aaaaaa"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "You're all caught up!"
                            font.pixelSize: 12
                            color: "#666666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}

// Individual notification item component
Component {
    id: notificationItemComponent
    
    Rectangle {
        id: notificationItem
        
        property string title: ""
        property string message: ""
        property string timestamp: ""
        property string type: "info"
        property bool read: false
        
        signal markAsRead()
        
        height: contentColumn.height + 24
        color: notificationItem.read ? "#2a2a2a" : "#333333"
        radius: 8
        border.color: notificationItem.read ? "transparent" : getTypeColor(notificationItem.type)
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
                    text: getTypeIcon(notificationItem.type)
                    font.pixelSize: 16
                }
                
                Text {
                    text: notificationItem.title
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#ffffff"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                
                Rectangle {
                    visible: !notificationItem.read
                    width: 8
                    height: 8
                    radius: 4
                    color: "#2196f3"
                }
            }
            
            Text {
                text: notificationItem.message
                font.pixelSize: 12
                color: "#cccccc"
                width: parent.width
                wrapMode: Text.WordWrap
            }
            
            Text {
                text: formatTimestamp(notificationItem.timestamp)
                font.pixelSize: 10
                color: "#888888"
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (!notificationItem.read) {
                    notificationItem.markAsRead()
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
}