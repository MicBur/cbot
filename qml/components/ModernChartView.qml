import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property var marketModel: null
    property string symbol: "AAPL"
    
    color: "#1e1e1e"
    radius: 8
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Header with symbol selector
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "📈 Charts"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Item { Layout.fillWidth: true }
            
            // Symbol selector
            ComboBox {
                id: symbolCombo
                Layout.preferredWidth: 120
                model: getSymbolList()
                currentIndex: findSymbolIndex(root.symbol)
                
                onCurrentTextChanged: {
                    if (currentText !== root.symbol) {
                        root.symbol = currentText
                    }
                }
                
                delegate: ItemDelegate {
                    width: symbolCombo.width
                    text: modelData
                    highlighted: symbolCombo.highlightedIndex === index
                }
            }
            
            // Timeframe selector
            Row {
                spacing: 4
                
                Repeater {
                    model: ["1D", "1W", "1M", "3M", "1Y"]
                    
                    Rectangle {
                        width: 32
                        height: 24
                        radius: 4
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
                                console.log("Timeframe selected:", modelData)
                                // TODO: Update chart timeframe
                            }
                        }
                    }
                }
            }
        }
        
        // Chart area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#2d2d2d"
            radius: 8
            border.color: "#404040"
            border.width: 1
            
            // Mock chart - in real app this would be a proper chart component
            Item {
                anchors.fill: parent
                anchors.margins: 16
                
                // Price info header
                Column {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    spacing: 4
                    
                    Text {
                        text: root.symbol
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    
                    Row {
                        spacing: 16
                        
                        Text {
                            text: "$" + getCurrentPrice().toFixed(2)
                            font.pixelSize: 16
                            color: "#ffffff"
                        }
                        
                        Text {
                            text: (getCurrentChange() > 0 ? "+" : "") + getCurrentChange().toFixed(2) + " (" + getCurrentChangePercent().toFixed(2) + "%)"
                            font.pixelSize: 14
                            color: getCurrentChange() > 0 ? "#4caf50" : "#f44336"
                        }
                    }
                }
                
                // Mock candlestick chart
                Canvas {
                    id: chartCanvas
                    anchors.fill: parent
                    anchors.topMargin: 80
                    
                    property var candleData: generateMockData()
                    
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        
                        if (candleData.length === 0) return
                        
                        var candleWidth = width / candleData.length * 0.8
                        var maxPrice = Math.max(...candleData.map(d => d.high))
                        var minPrice = Math.min(...candleData.map(d => d.low))
                        var priceRange = maxPrice - minPrice
                        
                        for (var i = 0; i < candleData.length; i++) {
                            var candle = candleData[i]
                            var x = i * (width / candleData.length) + candleWidth * 0.1
                            
                            var openY = height - ((candle.open - minPrice) / priceRange) * height
                            var closeY = height - ((candle.close - minPrice) / priceRange) * height
                            var highY = height - ((candle.high - minPrice) / priceRange) * height
                            var lowY = height - ((candle.low - minPrice) / priceRange) * height
                            
                            // Draw wick
                            ctx.strokeStyle = "#666666"
                            ctx.lineWidth = 1
                            ctx.beginPath()
                            ctx.moveTo(x + candleWidth / 2, highY)
                            ctx.lineTo(x + candleWidth / 2, lowY)
                            ctx.stroke()
                            
                            // Draw body
                            var isGreen = candle.close > candle.open
                            ctx.fillStyle = isGreen ? "#4caf50" : "#f44336"
                            ctx.strokeStyle = isGreen ? "#4caf50" : "#f44336"
                            ctx.lineWidth = 1
                            
                            var bodyTop = Math.min(openY, closeY)
                            var bodyHeight = Math.abs(closeY - openY)
                            
                            if (bodyHeight < 1) bodyHeight = 1
                            
                            ctx.fillRect(x, bodyTop, candleWidth, bodyHeight)
                            ctx.strokeRect(x, bodyTop, candleWidth, bodyHeight)
                        }
                    }
                    
                    Timer {
                        interval: 5000
                        running: true
                        repeat: true
                        onTriggered: {
                            chartCanvas.candleData = chartCanvas.generateMockData()
                            chartCanvas.requestPaint()
                        }
                    }
                    
                    function generateMockData() {
                        var data = []
                        var basePrice = getCurrentPrice()
                        
                        for (var i = 0; i < 50; i++) {
                            var open = basePrice + (Math.random() - 0.5) * 10
                            var close = open + (Math.random() - 0.5) * 5
                            var high = Math.max(open, close) + Math.random() * 3
                            var low = Math.min(open, close) - Math.random() * 3
                            
                            data.push({
                                open: open,
                                close: close,
                                high: high,
                                low: low
                            })
                            
                            basePrice = close
                        }
                        
                        return data
                    }
                }
                
                // Chart placeholder when no data
                Column {
                    visible: chartCanvas.candleData.length === 0
                    anchors.centerIn: parent
                    spacing: 16
                    
                    Text {
                        text: "📊"
                        font.pixelSize: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "Chart data loading..."
                        font.pixelSize: 16
                        color: "#aaaaaa"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
        
        // Chart controls
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Volume: " + formatVolume(getCurrentVolume())
                font.pixelSize: 12
                color: "#aaaaaa"
            }
            
            Item { Layout.fillWidth: true }
            
            Row {
                spacing: 8
                
                Rectangle {
                    width: 80
                    height: 28
                    radius: 14
                    color: "#333333"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "📊 Indicators"
                        font.pixelSize: 10
                        color: "#ffffff"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("Show indicators")
                            // TODO: Show indicators panel
                        }
                    }
                }
                
                Rectangle {
                    width: 60
                    height: 28
                    radius: 14
                    color: "#2196f3"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Trade"
                        font.pixelSize: 10
                        color: "#ffffff"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("Open trade dialog for", root.symbol)
                            // TODO: Open trading dialog
                        }
                    }
                }
            }
        }
    }
    
    function getSymbolList() {
        if (!root.marketModel) return ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"]
        
        var symbols = []
        for (var i = 0; i < root.marketModel.count; i++) {
            symbols.push(root.marketModel.get(i).symbol || "")
        }
        return symbols.length > 0 ? symbols : ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"]
    }
    
    function findSymbolIndex(symbol) {
        var symbols = getSymbolList()
        return Math.max(0, symbols.indexOf(symbol))
    }
    
    function getCurrentPrice() {
        if (!root.marketModel) return 150.0
        
        for (var i = 0; i < root.marketModel.count; i++) {
            var item = root.marketModel.get(i)
            if (item.symbol === root.symbol) {
                return item.price || 150.0
            }
        }
        return 150.0
    }
    
    function getCurrentChange() {
        if (!root.marketModel) return 2.5
        
        for (var i = 0; i < root.marketModel.count; i++) {
            var item = root.marketModel.get(i)
            if (item.symbol === root.symbol) {
                return item.change || 2.5
            }
        }
        return 2.5
    }
    
    function getCurrentChangePercent() {
        if (!root.marketModel) return 1.7
        
        for (var i = 0; i < root.marketModel.count; i++) {
            var item = root.marketModel.get(i)
            if (item.symbol === root.symbol) {
                return item.changePercent || 1.7
            }
        }
        return 1.7
    }
    
    function getCurrentVolume() {
        if (!root.marketModel) return 1250000
        
        for (var i = 0; i < root.marketModel.count; i++) {
            var item = root.marketModel.get(i)
            if (item.symbol === root.symbol) {
                return item.volume || 1250000
            }
        }
        return 1250000
    }
    
    function formatVolume(vol) {
        if (vol >= 1000000) {
            return (vol / 1000000).toFixed(1) + "M"
        } else if (vol >= 1000) {
            return (vol / 1000).toFixed(1) + "K"
        } else {
            return vol.toFixed(0)
        }
    }
}