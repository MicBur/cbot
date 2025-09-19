import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string ticker: ""
    property real qty: 0
    property real avgPrice: 0
    property real currentPrice: 0
    property string side: "long"
    
    height: 40
    color: index % 2 === 0 ? "#333333" : "#2a2a2a"
    
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
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        
        // Symbol
        Text {
            text: root.ticker
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#ffffff"
            Layout.preferredWidth: 80
        }
        
        // Shares
        Text {
            text: root.qty.toFixed(2)
            font.pixelSize: 14
            color: "#ffffff"
            Layout.preferredWidth: 80
        }
        
        // Average Price
        Text {
            text: "$" + root.avgPrice.toFixed(2)
            font.pixelSize: 14
            color: "#aaaaaa"
            Layout.preferredWidth: 100
        }
        
        // Current Price
        Text {
            text: "$" + root.currentPrice.toFixed(2)
            font.pixelSize: 14
            color: "#ffffff"
            Layout.preferredWidth: 100
        }
        
        // Market Value
        Text {
            text: "$" + (root.qty * root.currentPrice).toFixed(2)
            font.pixelSize: 14
            color: "#ffffff"
            Layout.preferredWidth: 120
        }
        
        // P&L (Profit/Loss)
        Text {
            property real pnl: (root.currentPrice - root.avgPrice) * root.qty
            text: (pnl > 0 ? "+" : "") + "$" + pnl.toFixed(2)
            font.pixelSize: 14
            color: pnl > 0 ? "#4caf50" : (pnl < 0 ? "#f44336" : "#ffffff")
            Layout.preferredWidth: 100
        }
        
        // P&L Percentage
        Text {
            property real pnlPercent: root.avgPrice > 0 ? ((root.currentPrice - root.avgPrice) / root.avgPrice * 100) : 0
            text: (pnlPercent > 0 ? "+" : "") + pnlPercent.toFixed(2) + "%"
            font.pixelSize: 14
            color: pnlPercent > 0 ? "#4caf50" : (pnlPercent < 0 ? "#f44336" : "#ffffff")
            Layout.preferredWidth: 80
        }
        
        // Side (Long/Short)
        Rectangle {
            width: 50
            height: 20
            radius: 10
            color: root.side === "long" ? "#4caf50" : "#f44336"
            Layout.preferredWidth: 60
            
            Text {
                anchors.centerIn: parent
                text: root.side.toUpperCase()
                font.pixelSize: 10
                font.weight: Font.Bold
                color: "white"
            }
        }
        
        Item { Layout.fillWidth: true }
        
        // Action buttons
        Row {
            spacing: 8
            
            Rectangle {
                width: 50
                height: 24
                radius: 12
                color: "#2196f3"
                opacity: buyMouseArea.containsMouse ? 1 : 0.7
                
                Text {
                    anchors.centerIn: parent
                    text: "Buy"
                    font.pixelSize: 10
                    color: "white"
                }
                
                MouseArea {
                    id: buyMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Buy more", root.ticker)
                        // TODO: Open buy dialog
                    }
                }
            }
            
            Rectangle {
                width: 50
                height: 24
                radius: 12
                color: "#f44336"
                opacity: sellMouseArea.containsMouse ? 1 : 0.7
                
                Text {
                    anchors.centerIn: parent
                    text: "Sell"
                    font.pixelSize: 10
                    color: "white"
                }
                
                MouseArea {
                    id: sellMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Sell", root.ticker)
                        // TODO: Open sell dialog
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
            console.log("Selected position:", root.ticker)
            // TODO: Show position details
        }
    }
}