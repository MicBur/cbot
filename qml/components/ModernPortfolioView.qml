import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var portfolioModel: null
    
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
                text: "💼 Portfolio"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
            
            Rectangle {
                width: 100
                height: 32
                radius: 16
                color: "#2196f3"
                
                Text {
                    anchors.centerIn: parent
                    text: "📊 Analytics"
                    font.pixelSize: 12
                    color: "#ffffff"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Show portfolio analytics")
                        // TODO: Show detailed analytics
                    }
                }
            }
        }
        
        // Portfolio Summary Cards
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 16
            rowSpacing: 16
            
            PortfolioSummaryCard {
                title: "Total Value"
                value: calculateTotalValue()
                unit: "$"
                trend: calculateTotalReturn()
                icon: "💰"
                Layout.fillWidth: true
            }
            
            PortfolioSummaryCard {
                title: "Day Change"
                value: calculateDayChange()
                unit: "$"
                trend: calculateDayChangePercent()
                icon: "📈"
                Layout.fillWidth: true
            }
            
            PortfolioSummaryCard {
                title: "Positions"
                value: root.portfolioModel ? root.portfolioModel.count : 0
                unit: ""
                trend: 0
                icon: "📊"
                Layout.fillWidth: true
            }
        }
        
        // Holdings Table
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
                    Text { text: "Shares"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Avg Price"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "Current"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "Market Value"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 120 }
                    Text { text: "P&L"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 100 }
                    Text { text: "P&L %"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 80 }
                    Text { text: "Side"; font.weight: Font.Bold; color: "#ffffff"; Layout.preferredWidth: 60 }
                    Item { Layout.fillWidth: true }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#404040"
                }
                
                // Portfolio Holdings List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: portfolioList
                        model: root.portfolioModel
                        spacing: 2
                        
                        delegate: PortfolioRowDelegate {
                            width: portfolioList.width
                            ticker: model.ticker || ""
                            qty: model.qty || 0
                            avgPrice: model.avgPrice || 0
                            currentPrice: getCurrentPrice(model.ticker || "")
                            side: model.side || "long"
                        }
                        
                        // Empty state
                        Rectangle {
                            visible: portfolioList.count === 0
                            anchors.centerIn: parent
                            width: 300
                            height: 200
                            color: "transparent"
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 16
                                
                                Text {
                                    text: "💼"
                                    font.pixelSize: 48
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "No positions"
                                    font.pixelSize: 16
                                    color: "#aaaaaa"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                Text {
                                    text: "Your portfolio is empty"
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
    function calculateTotalValue() {
        if (!root.portfolioModel) return 0
        
        let total = 0
        for (let i = 0; i < root.portfolioModel.count; i++) {
            let item = root.portfolioModel.get(i)
            let currentPrice = getCurrentPrice(item.ticker || "")
            total += (item.qty || 0) * currentPrice
        }
        return total
    }
    
    function calculateTotalReturn() {
        if (!root.portfolioModel) return 0
        
        let totalCost = 0
        let totalValue = 0
        
        for (let i = 0; i < root.portfolioModel.count; i++) {
            let item = root.portfolioModel.get(i)
            let currentPrice = getCurrentPrice(item.ticker || "")
            let qty = item.qty || 0
            let avgPrice = item.avgPrice || 0
            
            totalCost += qty * avgPrice
            totalValue += qty * currentPrice
        }
        
        return totalCost > 0 ? ((totalValue - totalCost) / totalCost * 100) : 0
    }
    
    function calculateDayChange() {
        // Mock calculation - in real app would use previous close prices
        return calculateTotalValue() * 0.015 // Assume 1.5% day change
    }
    
    function calculateDayChangePercent() {
        return 1.5 // Mock 1.5% change
    }
    
    function getCurrentPrice(symbol) {
        // This would normally get current market price
        // For now, return a mock price based on symbol
        const mockPrices = {
            "AAPL": 150.25,
            "GOOGL": 2750.50,
            "MSFT": 305.75,
            "TSLA": 850.00,
            "AMZN": 3200.25
        }
        return mockPrices[symbol] || 100.0
    }
}