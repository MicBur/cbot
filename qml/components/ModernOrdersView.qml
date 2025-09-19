import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var ordersModel: null
    
    color: "#1e1e1e"
    radius: 8
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "📋 Orders"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
            
            // Filter buttons
            Row {
                spacing: 4
                
                Repeater {
                    model: ["All", "Open", "Filled", "Cancelled"]
                    
                    Rectangle {
                        width: 60
                        height: 28
                        radius: 14
                        color: index === 0 ? "#2196f3" : "#333333"
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 10
                            color: "#ffffff"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Filter selected:", modelData)
                                // TODO: Apply filter
                            }
                        }
                    }
                }
            }
            
            Rectangle {
                width: 80
                height: 32
                radius: 16
                color: "#4caf50"
                
                Text {
                    anchors.centerIn: parent
                    text: "+ Order"
                    font.pixelSize: 12
                    color: "#ffffff"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Create new order")
                        // TODO: Open order creation dialog
                    }
                }
            }
        }
        
        // Order Statistics
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 16
            rowSpacing: 16
            
            OrderStatCard {
                title: "Total Orders"
                value: root.ordersModel ? root.ordersModel.count : 0
                icon: "📊"
                color: "#2196f3"
                Layout.fillWidth: true
            }
            
            OrderStatCard {
                title: "Open Orders"
                value: countOrdersByStatus("open")
                icon: "🔄"
                color: "#ff9800"
                Layout.fillWidth: true
            }
            
            OrderStatCard {
                title: "Filled Today"
                value: countOrdersByStatus("filled")
                icon: "✅"
                color: "#4caf50"
                Layout.fillWidth: true
            }
            
            OrderStatCard {
                title: "Cancelled"
                value: countOrdersByStatus("cancelled")
                icon: "❌"
                color: "#f44336"
                Layout.fillWidth: true
            }
        }
        
        // Orders Table
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#2d2d2d"
            radius: 8
            border.color: "#404040"
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    height: 32
                    
                    Text { text: "Symbol"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Side"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 60 }
                    Text { text: "Type"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Quantity"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Price"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "Status"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Filled"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Time"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 120 }
                    Item { Layout.fillWidth: true }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#404040"
                }
                
                // Orders List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: ordersList
                        model: root.ordersModel
                        spacing: 2
                        
                        delegate: OrderRowDelegate {
                            width: ordersList.width
                            symbol: model.ticker || model.symbol || ""
                            side: model.side || ""
                            orderType: model.type || model.orderType || "market"
                            quantity: model.qty || model.quantity || 0
                            price: model.price || 0
                            status: model.status || ""
                            filled: model.filled || model.filledQty || 0
                            timestamp: model.timestamp || ""
                            orderId: model.id || model.orderId || ""
                        }
                        
                        // Empty state
                        Rectangle {
                            visible: ordersList.count === 0
                            anchors.centerIn: parent
                            width: 300
                            height: 200
                            color: "transparent"
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 16
                                
                                Text {
                                    text: "📋"
                                    font.pixelSize: 48
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "No orders found"
                                    font.pixelSize: 16
                                    color: "#aaaaaa"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "Your order history is empty"
                                    font.pixelSize: 12
                                    color: "#666666"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Rectangle {
                                    width: 120
                                    height: 32
                                    radius: 16
                                    color: "#4caf50"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Create Order"
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            console.log("Create first order")
                                            // TODO: Open order creation dialog
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper functions
    function countOrdersByStatus(status) {
        if (!root.ordersModel) return 0
        
        let count = 0
        for (let i = 0; i < root.ordersModel.count; i++) {
            let item = root.ordersModel.get(i)
            if ((item.status || "").toLowerCase() === status.toLowerCase()) {
                count++
            }
        }
        return count
    }
}