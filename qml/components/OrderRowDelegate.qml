import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string symbol: ""
    property string side: ""
    property string orderType: ""
    property real quantity: 0
    property real price: 0
    property string status: ""
    property real filled: 0
    property string timestamp: ""
    property string orderId: ""
    
    height: 40
    color: index % 2 === 0 ? "#333333" : "#2a2a2a"
    
    // Status-based left border
    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        color: getStatusColor(root.status)
    }
    
    // Hover effect
    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        opacity: mouseArea.containsMouse ? 0.05 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        spacing: 16
        
        // Symbol
        Text {
            text: root.symbol
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#ffffff"
            Layout.preferredWidth: 80
        }
        
        // Side
        Rectangle {
            width: 40
            height: 20
            radius: 10
            color: root.side.toLowerCase() === "buy" ? "#4caf50" : "#f44336"
            Layout.preferredWidth: 60
            
            Text {
                anchors.centerIn: parent
                text: root.side.toUpperCase()
                font.pixelSize: 9
                font.weight: Font.Bold
                color: "white"
            }
        }
        
        // Order Type
        Text {
            text: root.orderType.toUpperCase()
            font.pixelSize: 12
            color: "#aaaaaa"
            Layout.preferredWidth: 80
        }
        
        // Quantity
        Text {
            text: root.quantity.toFixed(0)
            font.pixelSize: 14
            color: "#ffffff"
            Layout.preferredWidth: 80
        }
        
        // Price
        Text {
            text: root.orderType.toLowerCase() === "market" ? "MARKET" : "$" + root.price.toFixed(2)
            font.pixelSize: 14
            color: root.orderType.toLowerCase() === "market" ? "#ff9800" : "#ffffff"
            Layout.preferredWidth: 100
        }
        
        // Status
        Rectangle {
            width: 60
            height: 20
            radius: 10
            color: getStatusColor(root.status)
            Layout.preferredWidth: 80
            
            Text {
                anchors.centerIn: parent
                text: root.status.toUpperCase()
                font.pixelSize: 9
                font.weight: Font.Bold
                color: "white"
            }
        }
        
        // Filled
        Text {
            text: root.filled.toFixed(0) + "/" + root.quantity.toFixed(0)
            font.pixelSize: 12
            color: root.filled >= root.quantity ? "#4caf50" : "#aaaaaa"
            Layout.preferredWidth: 80
        }
        
        // Timestamp
        Text {
            text: formatTimestamp(root.timestamp)
            font.pixelSize: 11
            color: "#888888"
            Layout.preferredWidth: 120
        }
        
        Item { Layout.fillWidth: true }
        
        // Action buttons
        Row {
            spacing: 4
            visible: root.status.toLowerCase() === "open" || root.status.toLowerCase() === "pending"
            
            Rectangle {
                width: 50
                height: 24
                radius: 12
                color: "#ff9800"
                opacity: modifyMouseArea.containsMouse ? 1 : 0.7
                
                Text {
                    anchors.centerIn: parent
                    text: "Modify"
                    font.pixelSize: 9
                    color: "white"
                }
                
                MouseArea {
                    id: modifyMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Modify order", root.orderId)
                        // TODO: Open modify order dialog
                    }
                }
            }
            
            Rectangle {
                width: 50
                height: 24
                radius: 12
                color: "#f44336"
                opacity: cancelMouseArea.containsMouse ? 1 : 0.7
                
                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 9
                    color: "white"
                }
                
                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Cancel order", root.orderId)
                        // TODO: Cancel order
                    }
                }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            console.log("Selected order:", root.orderId)
            // TODO: Show order details
        }
    }
    
    function getStatusColor(status) {
        switch(status.toLowerCase()) {
            case "filled": return "#4caf50"
            case "open": 
            case "pending": return "#ff9800"
            case "cancelled": return "#f44336"
            case "rejected": return "#9c27b0"
            case "expired": return "#607d8b"
            default: return "#2196f3"
        }
    }
    
    function formatTimestamp(timestamp) {
        if (!timestamp) return ""
        
        let date = new Date(timestamp)
        return date.toLocaleDateString() + " " + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
    }
}