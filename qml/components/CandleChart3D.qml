import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

/*
  CandleChart3D - Modern 3D-style candlestick chart with depth effects
  Using Canvas for pseudo-3D rendering with perspective, shadows, and glow effects
*/
Item {
    id: root
    
    property var modelCandles: chartDataModel
    property var modelForecast: predictionsModel
    property string currentTicker: poller ? poller.currentSymbol : "AAPL"
    property int maxCandles: 60
    property real rotationY: 0
    property real perspectiveDepth: 30
    property bool showGrid: true
    property bool showGlow: true
    property real animationProgress: 0
    
    implicitHeight: 400
    
    // Animation on component load
    Component.onCompleted: loadAnimation.start()
    
    NumberAnimation {
        id: loadAnimation
        target: root
        property: "animationProgress"
        from: 0
        to: 1
        duration: Theme.durSlow * 2
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
        
        // Glass morphism effect
        Rectangle {
            anchors.fill: parent
            color: Theme.bgGlass
            radius: parent.radius
            border.color: Theme.border
            border.width: 1
        }
    }
    
    // Glow effect backdrop
    Rectangle {
        id: glowBackdrop
        anchors.centerIn: canvas
        width: canvas.width + 100
        height: canvas.height + 100
        color: "transparent"
        visible: showGlow
        
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) }
                GradientStop { position: 0.5; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        // Pulsing glow animation
        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { from: 0.3; to: 0.6; duration: Theme.durGlow * 2; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.6; to: 0.3; duration: Theme.durGlow * 2; easing.type: Easing.InOutSine }
        }
    }
    
    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 20
        
        property real depth3D: perspectiveDepth * animationProgress
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.save();
            
            // Clear canvas
            ctx.clearRect(0, 0, width, height);
            
            // Get data
            var data = [];
            if (modelCandles && modelCandles.rowCount() > 0) {
                for (var i = Math.max(0, modelCandles.rowCount() - maxCandles); i < modelCandles.rowCount(); i++) {
                    var o = modelCandles.data(modelCandles.index(i,0), modelCandles.CloseRole);
                    var h = modelCandles.data(modelCandles.index(i,0), modelCandles.HighRole);
                    var l = modelCandles.data(modelCandles.index(i,0), modelCandles.LowRole);
                    var c = modelCandles.data(modelCandles.index(i,0), modelCandles.CloseRole);
                    var t = modelCandles.data(modelCandles.index(i,0), modelCandles.TimeRole);
                    data.push({o:o, h:h, l:l, c:c, t:t});
                }
            }
            
            if (data.length === 0) {
                // Generate mock data for demo
                var base = 150;
                for (var j = 0; j < 40; j++) {
                    var open = base + (Math.random() - 0.5) * 3;
                    var close = open + (Math.random() - 0.5) * 5;
                    var high = Math.max(open, close) + Math.random() * 2;
                    var low = Math.min(open, close) - Math.random() * 2;
                    data.push({o: open, h: high, l: low, c: close, t: j});
                    base = close;
                }
            }
            
            // Calculate bounds
            var minPrice = Math.min(...data.map(d => d.l));
            var maxPrice = Math.max(...data.map(d => d.h));
            var priceRange = maxPrice - minPrice;
            if (priceRange <= 0) priceRange = 1;
            
            var chartWidth = width * 0.8;
            var chartHeight = height * 0.7;
            var chartX = width * 0.1;
            var chartY = height * 0.1;
            
            // Draw grid with 3D perspective
            if (showGrid) {
                ctx.strokeStyle = Theme.chartGrid;
                ctx.lineWidth = 1;
                ctx.globalAlpha = 0.3 * animationProgress;
                
                // Horizontal grid lines
                for (var g = 0; g <= 5; g++) {
                    var y = chartY + (g / 5) * chartHeight;
                    ctx.beginPath();
                    ctx.moveTo(chartX, y);
                    ctx.lineTo(chartX + chartWidth, y);
                    // 3D depth line
                    ctx.lineTo(chartX + chartWidth + depth3D, y - depth3D);
                    ctx.stroke();
                }
                
                // Vertical grid lines
                var gridStep = Math.floor(data.length / 5);
                for (var v = 0; v <= 5; v++) {
                    var x = chartX + (v / 5) * chartWidth;
                    ctx.beginPath();
                    ctx.moveTo(x, chartY);
                    ctx.lineTo(x, chartY + chartHeight);
                    // 3D depth line
                    ctx.lineTo(x + depth3D, chartY + chartHeight - depth3D);
                    ctx.stroke();
                }
            }
            
            ctx.globalAlpha = animationProgress;
            
            // Draw candles with 3D effect
            var candleWidth = chartWidth / data.length;
            var candleBodyWidth = candleWidth * 0.7;
            
            for (var idx = 0; idx < data.length; idx++) {
                var candle = data[idx];
                var x = chartX + idx * candleWidth + candleWidth / 2;
                
                // Calculate Y positions
                var yHigh = chartY + (1 - (candle.h - minPrice) / priceRange) * chartHeight;
                var yLow = chartY + (1 - (candle.l - minPrice) / priceRange) * chartHeight;
                var yOpen = chartY + (1 - (candle.o - minPrice) / priceRange) * chartHeight;
                var yClose = chartY + (1 - (candle.c - minPrice) / priceRange) * chartHeight;
                
                var isBullish = candle.c >= candle.o;
                var bodyTop = isBullish ? yClose : yOpen;
                var bodyBottom = isBullish ? yOpen : yClose;
                var bodyHeight = Math.max(2, Math.abs(bodyBottom - bodyTop));
                
                // Shadow/wick with glow
                ctx.strokeStyle = Theme.textDim;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(x, yHigh);
                ctx.lineTo(x, yLow);
                ctx.stroke();
                
                // 3D body effect
                var depthOffset = (1 - idx / data.length) * depth3D * 0.5;
                
                // Draw 3D sides
                ctx.fillStyle = isBullish ? Qt.darker(Theme.success, 1.5) : Qt.darker(Theme.danger, 1.5);
                ctx.beginPath();
                ctx.moveTo(x - candleBodyWidth/2, bodyTop);
                ctx.lineTo(x - candleBodyWidth/2 + depthOffset, bodyTop - depthOffset);
                ctx.lineTo(x - candleBodyWidth/2 + depthOffset, bodyBottom - depthOffset);
                ctx.lineTo(x - candleBodyWidth/2, bodyBottom);
                ctx.closePath();
                ctx.fill();
                
                ctx.beginPath();
                ctx.moveTo(x + candleBodyWidth/2, bodyTop);
                ctx.lineTo(x + candleBodyWidth/2 + depthOffset, bodyTop - depthOffset);
                ctx.lineTo(x + candleBodyWidth/2 + depthOffset, bodyBottom - depthOffset);
                ctx.lineTo(x + candleBodyWidth/2, bodyBottom);
                ctx.closePath();
                ctx.fill();
                
                // Draw body front face with gradient
                var gradient = ctx.createLinearGradient(x - candleBodyWidth/2, bodyTop, x + candleBodyWidth/2, bodyBottom);
                if (isBullish) {
                    gradient.addColorStop(0, Theme.success);
                    gradient.addColorStop(0.5, Qt.lighter(Theme.success, 1.2));
                    gradient.addColorStop(1, Theme.success);
                } else {
                    gradient.addColorStop(0, Theme.danger);
                    gradient.addColorStop(0.5, Qt.lighter(Theme.danger, 1.2));
                    gradient.addColorStop(1, Theme.danger);
                }
                ctx.fillStyle = gradient;
                ctx.fillRect(x - candleBodyWidth/2, bodyTop, candleBodyWidth, bodyHeight);
                
                // Add glow effect for recent candles
                if (idx >= data.length - 5 && showGlow) {
                    ctx.save();
                    ctx.globalAlpha = 0.3 * (1 - (data.length - idx) / 5) * animationProgress;
                    ctx.shadowColor = isBullish ? Theme.successGlow : Theme.dangerGlow;
                    ctx.shadowBlur = 10;
                    ctx.fillRect(x - candleBodyWidth/2, bodyTop, candleBodyWidth, bodyHeight);
                    ctx.restore();
                }
            }
            
            // Draw forecast line with glow
            if (modelForecast && modelForecast.rowCount() > 0) {
                ctx.save();
                ctx.setLineDash([4, 4]);
                ctx.strokeStyle = Theme.accent;
                ctx.lineWidth = 2.5;
                ctx.shadowColor = Theme.accentGlow;
                ctx.shadowBlur = 15;
                ctx.globalAlpha = 0.8 * animationProgress;
                
                ctx.beginPath();
                var lastCandle = data[data.length - 1];
                var startX = chartX + (data.length - 1) * candleWidth + candleWidth / 2;
                var startY = chartY + (1 - (lastCandle.c - minPrice) / priceRange) * chartHeight;
                ctx.moveTo(startX, startY);
                
                for (var f = 0; f < Math.min(10, modelForecast.rowCount()); f++) {
                    var forecastValue = modelForecast.data(modelForecast.index(f, 0), modelForecast.ValueRole);
                    var fx = startX + (f + 1) * candleWidth;
                    var fy = chartY + (1 - (forecastValue - minPrice) / priceRange) * chartHeight;
                    ctx.lineTo(fx, fy);
                }
                ctx.stroke();
                ctx.restore();
            }
            
            ctx.restore();
        }
        
        // Repaint triggers
        Connections { 
            target: chartDataModel
            function onDataChanged() { canvas.requestPaint(); }
        }
        Connections { 
            target: predictionsModel
            function onDataChanged() { canvas.requestPaint(); }
        }
        Connections {
            target: root
            function onAnimationProgressChanged() { canvas.requestPaint(); }
        }
    }
    
    // Header overlay with modern styling
    Rectangle {
        id: headerOverlay
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        height: 60
        color: Theme.bgGlass
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 20
            
            // Ticker symbol with glow
            Rectangle {
                width: 80
                height: 40
                color: "transparent"
                radius: Theme.radius
                
                Text {
                    anchors.centerIn: parent
                    text: root.currentTicker
                    color: Theme.accent
                    font.pixelSize: 24
                    font.bold: true
                    font.family: "Consolas, Monaco, monospace"
                    
                    layer.enabled: showGlow
                    layer.effect: Glow {
                        radius: 8
                        color: Theme.accentGlow
                        samples: 16
                        spread: 0.3
                    }
                }
            }
            
            // Price info
            Column {
                Text {
                    text: {
                        if (!modelCandles || modelCandles.rowCount() === 0) return "---"
                        var lastIdx = modelCandles.rowCount() - 1;
                        var price = modelCandles.data(modelCandles.index(lastIdx, 0), modelCandles.CloseRole);
                        return "$" + Number(price).toFixed(2);
                    }
                    color: Theme.text
                    font.pixelSize: 20
                    font.bold: true
                }
                Text {
                    text: {
                        if (!modelCandles || modelCandles.rowCount() < 2) return "---"
                        var lastIdx = modelCandles.rowCount() - 1;
                        var price = modelCandles.data(modelCandles.index(lastIdx, 0), modelCandles.CloseRole);
                        var prevPrice = modelCandles.data(modelCandles.index(lastIdx - 1, 0), modelCandles.CloseRole);
                        var change = price - prevPrice;
                        var pct = (change / prevPrice) * 100;
                        var prefix = change >= 0 ? "+" : "";
                        return prefix + change.toFixed(2) + " (" + prefix + pct.toFixed(2) + "%)"
                    }
                    color: {
                        if (!modelCandles || modelCandles.rowCount() < 2) return Theme.textDim;
                        var lastIdx = modelCandles.rowCount() - 1;
                        var price = modelCandles.data(modelCandles.index(lastIdx, 0), modelCandles.CloseRole);
                        var prevPrice = modelCandles.data(modelCandles.index(lastIdx - 1, 0), modelCandles.CloseRole);
                        return price >= prevPrice ? Theme.success : Theme.danger;
                    }
                    font.pixelSize: 14
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // View controls
            Row {
                spacing: 10
                
                Button {
                    text: "Grid"
                    checkable: true
                    checked: showGrid
                    onClicked: showGrid = !showGrid
                    width: 60
                    height: 30
                }
                
                Button {
                    text: "Glow"
                    checkable: true
                    checked: showGlow
                    onClicked: showGlow = !showGlow
                    width: 60
                    height: 30
                }
            }
        }
    }
    
    // Loading animation
    Rectangle {
        anchors.centerIn: parent
        width: 100
        height: 100
        color: Theme.bgCard
        radius: 50
        visible: animationProgress < 0.1
        
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: parent.height - 20
            color: "transparent"
            radius: parent.radius
            border.color: Theme.accent
            border.width: 3
            
            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }
    }
}