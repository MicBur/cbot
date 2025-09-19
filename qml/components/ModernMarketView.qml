import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var marketModel: null
    
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
                text: "📊 Market Overview"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "Live Data"
                font.pixelSize: 12
                color: "#4caf50"
            }
            
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: "#4caf50"
                
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite
                    
                    PropertyAnimation {
                        target: parent
                        property: "opacity"
                        from: 1.0
                        to: 0.3
                        duration: 1000
                    }
                    
                    PropertyAnimation {
                        target: parent
                        property: "opacity"
                        from: 0.3
                        to: 1.0
                        duration: 1000
                    }
                }
            }
        }
        
        // Market Statistics Cards
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 16
            rowSpacing: 16
            
            // Market Stats Cards
            MarketStatCard {
                title: "Total Volume"
                value: calculateTotalVolume()
                unit: "M"
                trend: 2.5
                icon: "📈"
            }
            
            MarketStatCard {
                title: "Active Symbols"
                value: root.marketModel ? root.marketModel.count : 0
                unit: ""
                trend: 0
                icon: "🔢"
            }
            
            MarketStatCard {
                title: "Avg Change"
                value: calculateAverageChange()
                unit: "%"
                trend: calculateAverageChange()
                icon: "📊"
            }
            
            MarketStatCard {
                title: "Market Cap"
                value: 2847.3
                unit: "B"
                trend: 1.2
                icon: "💰"
            }
        }
        
        // Market Table
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
                    Text { text: "Price"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "Change"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Change %"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Volume"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "High"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Low"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Item { Layout.fillWidth: true }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#404040"
                }
                
                // Market Data List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: marketList
                        model: root.marketModel
                        spacing: 2
                        
                        delegate: MarketRowDelegate {
                            width: marketList.width
                            symbol: model.symbol || ""
                            price: model.price || 0
                            change: model.change || 0
                            changePercent: model.changePercent || 0
                            volume: model.volume || 0
                            high: model.high || 0
                            low: model.low || 0
                        }
                        
                        // Empty state
                        Rectangle {
                            visible: marketList.count === 0
                            anchors.centerIn: parent
                            width: 300
                            height: 200
                            color: "transparent"
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 16
                                
                                Text {
                                    text: "📊"
                                    font.pixelSize: 48
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "No market data available"
                                    font.pixelSize: 16
                                    color: "#aaaaaa"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "Waiting for connection..."
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
    }
    
    // Helper functions
    function calculateTotalVolume() {
        if (!root.marketModel) return 0
        
        let total = 0
        for (let i = 0; i < root.marketModel.count; i++) {
            let item = root.marketModel.get(i)
            total += (item.volume || 0)
        }
        return (total / 1000000).toFixed(1) // Convert to millions
    }
    
    function calculateAverageChange() {
        if (!root.marketModel || root.marketModel.count === 0) return 0
        
        let total = 0
        for (let i = 0; i < root.marketModel.count; i++) {
            let item = root.marketModel.get(i)
            total += (item.changePercent || 0)
        }
        return (total / root.marketModel.count).toFixed(2)
    }
}