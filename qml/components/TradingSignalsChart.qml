import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

Item {
    id: root
    
    property var candlesModel: chartData7dModel
    property var predictionsModel: predictions7dModel
    property var signalsModel: tradingSignalsModel
    property string currentTicker: poller ? poller.currentSymbol : "AAPL"
    property real botAggressiveness: 0.5
    property bool showSignals: true
    property bool showPredictionBand: true
    property real animationProgress: 0
    
    implicitHeight: 500
    
    Component.onCompleted: loadAnimation.start()
    
    NumberAnimation {
        id: loadAnimation
        target: root
        property: "animationProgress"
        from: 0
        to: 1
        duration: Theme.durSlow
        easing.type: Easing.OutExpo
    }
    
    // Background with gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgCard }
            GradientStop { position: 1.0; color: Theme.bg }
        }
        radius: Theme.radiusLarge
        border.color: Theme.border
        border.width: 1
    }
    
    // Main chart canvas
    Canvas {
        id: chartCanvas
        anchors.fill: parent
        anchors.margins: 20
        
        property real maxDays: 14 // 7 days history + 7 days forecast
        property real chartPadding: 60
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.save();
            
            var chartWidth = width - chartPadding * 2;
            var chartHeight = height - chartPadding * 2;
            var chartX = chartPadding;
            var chartY = chartPadding;
            
            // Get data ranges
            var priceData = [];
            var minPrice = Infinity;
            var maxPrice = -Infinity;
            
            // Process historical candles (last 7 days)
            if (candlesModel && candlesModel.rowCount() > 0) {
                for (var i = 0; i < candlesModel.rowCount(); i++) {
                    var candle = {
                        t: candlesModel.data(candlesModel.index(i, 0), candlesModel.TimeRole),
                        o: candlesModel.data(candlesModel.index(i, 0), candlesModel.OpenRole),
                        h: candlesModel.data(candlesModel.index(i, 0), candlesModel.HighRole),
                        l: candlesModel.data(candlesModel.index(i, 0), candlesModel.LowRole),
                        c: candlesModel.data(candlesModel.index(i, 0), candlesModel.CloseRole),
                        v: candlesModel.data(candlesModel.index(i, 0), candlesModel.VolumeRole),
                        type: "historical"
                    };
                    priceData.push(candle);
                    minPrice = Math.min(minPrice, candle.l);
                    maxPrice = Math.max(maxPrice, candle.h);
                }
            }
            
            // Process predictions (next 7 days)
            if (predictionsModel && predictionsModel.rowCount() > 0) {
                for (var p = 0; p < predictionsModel.rowCount(); p++) {
                    var pred = {
                        t: predictionsModel.data(predictionsModel.index(p, 0), predictionsModel.TimeRole),
                        v: predictionsModel.data(predictionsModel.index(p, 0), predictionsModel.ValueRole),
                        conf: predictionsModel.data(predictionsModel.index(p, 0), predictionsModel.ConfidenceRole),
                        type: "prediction"
                    };
                    priceData.push(pred);
                    minPrice = Math.min(minPrice, pred.v * 0.95); // Add margin
                    maxPrice = Math.max(maxPrice, pred.v * 1.05);
                }
            }
            
            var priceRange = maxPrice - minPrice;
            if (priceRange <= 0) priceRange = 1;
            
            // Draw grid
            ctx.strokeStyle = Theme.chartGrid;
            ctx.lineWidth = 1;
            ctx.globalAlpha = 0.3;
            
            // Horizontal grid lines
            for (var g = 0; g <= 10; g++) {
                var y = chartY + (g / 10) * chartHeight;
                ctx.beginPath();
                ctx.moveTo(chartX, y);
                ctx.lineTo(chartX + chartWidth, y);
                ctx.stroke();
                
                // Price labels
                ctx.fillStyle = Theme.textDim;
                ctx.font = "10px monospace";
                ctx.textAlign = "right";
                var price = maxPrice - (g / 10) * priceRange;
                ctx.fillText("$" + price.toFixed(2), chartX - 5, y + 3);
            }
            
            // Vertical grid lines (days)
            for (var d = 0; d <= 14; d++) {
                var x = chartX + (d / 14) * chartWidth;
                ctx.beginPath();
                ctx.moveTo(x, chartY);
                ctx.lineTo(x, chartY + chartHeight);
                ctx.stroke();
                
                // Day labels
                if (d % 2 === 0) {
                    ctx.fillStyle = Theme.textDim;
                    ctx.font = "10px sans-serif";
                    ctx.textAlign = "center";
                    var dayLabel = d < 7 ? "D-" + (7-d) : "D+" + (d-7);
                    ctx.fillText(dayLabel, x, chartY + chartHeight + 15);
                }
            }
            
            // Draw separator between history and forecast
            ctx.strokeStyle = Theme.accent;
            ctx.lineWidth = 2;
            ctx.globalAlpha = 0.5;
            ctx.setLineDash([5, 5]);
            var separatorX = chartX + (7 / 14) * chartWidth;
            ctx.beginPath();
            ctx.moveTo(separatorX, chartY);
            ctx.lineTo(separatorX, chartY + chartHeight);
            ctx.stroke();
            ctx.setLineDash([]);
            
            ctx.globalAlpha = animationProgress;
            
            // Draw historical candles
            var historicalData = priceData.filter(d => d.type === "historical");
            if (historicalData.length > 0) {
                var candleWidth = (chartWidth / 14) / 12; // Assuming 5-min candles
                
                historicalData.forEach(function(candle, idx) {
                    var x = chartX + (idx / priceData.length) * chartWidth;
                    var yHigh = chartY + (1 - (candle.h - minPrice) / priceRange) * chartHeight;
                    var yLow = chartY + (1 - (candle.l - minPrice) / priceRange) * chartHeight;
                    var yOpen = chartY + (1 - (candle.o - minPrice) / priceRange) * chartHeight;
                    var yClose = chartY + (1 - (candle.c - minPrice) / priceRange) * chartHeight;
                    
                    var isBullish = candle.c >= candle.o;
                    
                    // Draw wick
                    ctx.strokeStyle = Theme.textDim;
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(x, yHigh);
                    ctx.lineTo(x, yLow);
                    ctx.stroke();
                    
                    // Draw body
                    ctx.fillStyle = isBullish ? Theme.success : Theme.danger;
                    var bodyTop = isBullish ? yClose : yOpen;
                    var bodyHeight = Math.abs(yClose - yOpen);
                    ctx.fillRect(x - candleWidth/2, bodyTop, candleWidth, Math.max(1, bodyHeight));
                });
            }
            
            // Draw prediction line with confidence band
            var predictionData = priceData.filter(d => d.type === "prediction");
            if (predictionData.length > 0 && showPredictionBand) {
                // Draw confidence band
                ctx.fillStyle = Theme.chartFill;
                ctx.globalAlpha = 0.2 * animationProgress;
                ctx.beginPath();
                
                predictionData.forEach(function(pred, idx) {
                    var x = separatorX + (idx / predictionData.length) * (chartWidth / 2);
                    var conf = pred.conf || 0.8;
                    var margin = priceRange * 0.05 * (1 - conf);
                    var yTop = chartY + (1 - (pred.v + margin - minPrice) / priceRange) * chartHeight;
                    var yBottom = chartY + (1 - (pred.v - margin - minPrice) / priceRange) * chartHeight;
                    
                    if (idx === 0) {
                        ctx.moveTo(x, yTop);
                    } else {
                        ctx.lineTo(x, yTop);
                    }
                });
                
                for (var i = predictionData.length - 1; i >= 0; i--) {
                    var pred2 = predictionData[i];
                    var x2 = separatorX + (i / predictionData.length) * (chartWidth / 2);
                    var conf2 = pred2.conf || 0.8;
                    var margin2 = priceRange * 0.05 * (1 - conf2);
                    var yBottom2 = chartY + (1 - (pred2.v - margin2 - minPrice) / priceRange) * chartHeight;
                    ctx.lineTo(x2, yBottom2);
                }
                
                ctx.closePath();
                ctx.fill();
                
                // Draw prediction line
                ctx.strokeStyle = Theme.accent;
                ctx.lineWidth = 2.5;
                ctx.globalAlpha = 0.9 * animationProgress;
                ctx.shadowColor = Theme.accentGlow;
                ctx.shadowBlur = 10;
                ctx.beginPath();
                
                predictionData.forEach(function(pred, idx) {
                    var x = separatorX + (idx / predictionData.length) * (chartWidth / 2);
                    var y = chartY + (1 - (pred.v - minPrice) / priceRange) * chartHeight;
                    
                    if (idx === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                });
                
                ctx.stroke();
                ctx.shadowBlur = 0;
            }
            
            // Draw trading signals
            if (showSignals && signalsModel && signalsModel.rowCount() > 0) {
                for (var s = 0; s < signalsModel.rowCount(); s++) {
                    var signal = {
                        timestamp: signalsModel.data(signalsModel.index(s, 0), signalsModel.TimestampRole),
                        type: signalsModel.data(signalsModel.index(s, 0), signalsModel.TypeRole),
                        price: signalsModel.data(signalsModel.index(s, 0), signalsModel.PriceRole),
                        confidence: signalsModel.data(signalsModel.index(s, 0), signalsModel.ConfidenceRole)
                    };
                    
                    // Calculate x position based on timestamp
                    var signalX = chartX + (signal.timestamp / maxDays) * chartWidth;
                    var signalY = chartY + (1 - (signal.price - minPrice) / priceRange) * chartHeight;
                    
                    // Draw signal marker
                    ctx.save();
                    ctx.globalAlpha = 0.8 * animationProgress;
                    
                    if (signal.type === "BUY") {
                        // Green up arrow
                        ctx.fillStyle = Theme.success;
                        ctx.strokeStyle = Theme.successGlow;
                        ctx.shadowColor = Theme.successGlow;
                        ctx.shadowBlur = 10;
                        
                        ctx.beginPath();
                        ctx.moveTo(signalX, signalY - 10);
                        ctx.lineTo(signalX - 8, signalY + 5);
                        ctx.lineTo(signalX + 8, signalY + 5);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                    } else {
                        // Red down arrow
                        ctx.fillStyle = Theme.danger;
                        ctx.strokeStyle = Theme.dangerGlow;
                        ctx.shadowColor = Theme.dangerGlow;
                        ctx.shadowBlur = 10;
                        
                        ctx.beginPath();
                        ctx.moveTo(signalX, signalY + 10);
                        ctx.lineTo(signalX - 8, signalY - 5);
                        ctx.lineTo(signalX + 8, signalY - 5);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                    }
                    
                    // Confidence indicator
                    ctx.shadowBlur = 0;
                    ctx.globalAlpha = signal.confidence * animationProgress;
                    ctx.beginPath();
                    ctx.arc(signalX, signalY, 15, 0, 2 * Math.PI);
                    ctx.strokeStyle = signal.type === "BUY" ? Theme.success : Theme.danger;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    
                    ctx.restore();
                }
            }
            
            ctx.restore();
        }
        
        // Repaint on data changes
        Connections {
            target: candlesModel
            function onDataChanged() { chartCanvas.requestPaint(); }
        }
        Connections {
            target: predictionsModel
            function onDataChanged() { chartCanvas.requestPaint(); }
        }
        Connections {
            target: signalsModel
            function onDataChanged() { chartCanvas.requestPaint(); }
        }
        Connections {
            target: root
            function onAnimationProgressChanged() { chartCanvas.requestPaint(); }
        }
    }
    
    // Control panel
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 300
        height: 200
        radius: Theme.radius
        color: Theme.bgGlass
        border.color: Theme.border
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12
            
            Text {
                text: "Bot Trading Controls"
                color: Theme.accent
                font.pixelSize: 16
                font.bold: true
            }
            
            // Aggressiveness slider
            Column {
                Layout.fillWidth: true
                spacing: 6
                
                RowLayout {
                    width: parent.width
                    
                    Text {
                        text: "Aggressiveness"
                        color: Theme.text
                        font.pixelSize: 12
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: (root.botAggressiveness * 100).toFixed(0) + "%"
                        color: Theme.accent
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
                
                Slider {
                    id: aggressivenessSlider
                    width: parent.width
                    from: 0
                    to: 1
                    value: root.botAggressiveness
                    onValueChanged: {
                        root.botAggressiveness = value
                        // Update backend
                        poller.updateBotConfig("aggressiveness", value)
                    }
                    
                    background: Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.success }
                            GradientStop { position: 0.5; color: Theme.warning }
                            GradientStop { position: 1.0; color: Theme.danger }
                        }
                    }
                    
                    handle: Rectangle {
                        x: aggressivenessSlider.visualPosition * (aggressivenessSlider.width - width)
                        y: (aggressivenessSlider.height - height) / 2
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.accent
                        border.color: Theme.bg
                        border.width: 2
                        
                        layer.enabled: true
                        layer.effect: Glow {
                            radius: 8
                            color: Theme.accentGlow
                            samples: 16
                            spread: 0.5
                        }
                    }
                }
                
                Row {
                    width: parent.width
                    
                    Text {
                        text: "Conservative"
                        color: Theme.textDim
                        font.pixelSize: 10
                    }
                    
                    Item { width: parent.width - 150 }
                    
                    Text {
                        text: "Aggressive"
                        color: Theme.textDim
                        font.pixelSize: 10
                    }
                }
            }
            
            // Toggle switches
            Column {
                spacing: 8
                
                RowLayout {
                    CheckBox {
                        checked: showSignals
                        onCheckedChanged: showSignals = checked
                    }
                    Text {
                        text: "Show Buy/Sell Signals"
                        color: Theme.text
                        font.pixelSize: 12
                    }
                }
                
                RowLayout {
                    CheckBox {
                        checked: showPredictionBand
                        onCheckedChanged: showPredictionBand = checked
                    }
                    Text {
                        text: "Show Confidence Band"
                        color: Theme.text
                        font.pixelSize: 12
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            // Bot status
            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 15
                color: botEnabled ? Theme.success : Theme.danger
                opacity: 0.2
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: botEnabled ? Theme.success : Theme.danger
                        
                        SequentialAnimation on opacity {
                            running: botEnabled
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.5; to: 1; duration: 500 }
                            NumberAnimation { from: 1; to: 0.5; duration: 500 }
                        }
                    }
                    
                    Text {
                        text: botEnabled ? "Bot Active" : "Bot Inactive"
                        color: Theme.text
                        font.pixelSize: 12
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Switch {
                        checked: botEnabled
                        onCheckedChanged: {
                            botEnabled = checked
                            poller.updateBotConfig("enabled", checked)
                        }
                    }
                }
            }
        }
    }
    
    // Legend
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        width: 250
        height: 60
        radius: Theme.radius
        color: Theme.bgGlass
        border.color: Theme.border
        border.width: 1
        
        Row {
            anchors.centerIn: parent
            spacing: 20
            
            Row {
                spacing: 6
                Rectangle { width: 20; height: 3; color: Theme.textDim }
                Text { text: "Historical"; color: Theme.textDim; font.pixelSize: 11 }
            }
            
            Row {
                spacing: 6
                Rectangle { width: 20; height: 3; color: Theme.accent }
                Text { text: "Prediction"; color: Theme.textDim; font.pixelSize: 11 }
            }
            
            Row {
                spacing: 6
                Text { text: "▲"; color: Theme.success; font.pixelSize: 14 }
                Text { text: "Buy"; color: Theme.textDim; font.pixelSize: 11 }
            }
            
            Row {
                spacing: 6
                Text { text: "▼"; color: Theme.danger; font.pixelSize: 14 }
                Text { text: "Sell"; color: Theme.textDim; font.pixelSize: 11 }
            }
        }
    }
    
    property bool botEnabled: true
}