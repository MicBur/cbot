import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

/*
  Portfolio3D - 3D Donut chart visualization for portfolio holdings
*/
Item {
    id: root
    
    property var model: portfolioModel
    property real rotationAngle: 0
    property real tiltAngle: 60  // Tilt for 3D effect
    property bool autoRotate: true
    property real hoverIndex: -1
    property real animationProgress: 0
    
    implicitHeight: 400
    implicitWidth: 400
    
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
    
    // Auto rotation
    NumberAnimation {
        running: autoRotate
        target: root
        property: "rotationAngle"
        from: 0
        to: 360
        duration: 20000
        loops: Animation.Infinite
    }
    
    // Background with radial gradient
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) }
                GradientStop { position: 0.7; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.bg }
            }
        }
    }
    
    // Calculate portfolio data
    property var portfolioData: {
        if (!model || model.rowCount() === 0) return [];
        
        var data = [];
        var total = 0;
        
        // Calculate total value
        for (var i = 0; i < model.rowCount(); i++) {
            var qty = model.data(model.index(i, 0), Qt.UserRole + 2);
            var avgPrice = model.data(model.index(i, 0), Qt.UserRole + 3);
            var value = qty * avgPrice;
            total += value;
        }
        
        // Calculate percentages and angles
        var currentAngle = 0;
        for (var j = 0; j < model.rowCount(); j++) {
            var ticker = model.data(model.index(j, 0), Qt.UserRole + 1);
            var qtyJ = model.data(model.index(j, 0), Qt.UserRole + 2);
            var avgPriceJ = model.data(model.index(j, 0), Qt.UserRole + 3);
            var side = model.data(model.index(j, 0), Qt.UserRole + 4);
            var valueJ = qtyJ * avgPriceJ;
            var percentage = (valueJ / total) * 100;
            var angleSpan = (valueJ / total) * 360;
            
            data.push({
                ticker: ticker,
                qty: qtyJ,
                avgPrice: avgPriceJ,
                value: valueJ,
                percentage: percentage,
                startAngle: currentAngle,
                angleSpan: angleSpan,
                side: side,
                color: Qt.hsla((j * 0.15) % 1, 0.7, 0.5, 1)
            });
            
            currentAngle += angleSpan;
        }
        
        return data;
    }
    
    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.8
        height: width
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.save();
            
            var centerX = width / 2;
            var centerY = height / 2;
            var outerRadius = width * 0.35;
            var innerRadius = outerRadius * 0.6;
            var depth = 30 * animationProgress;
            
            // Apply 3D transformation
            ctx.translate(centerX, centerY);
            
            // Draw shadow
            ctx.save();
            ctx.globalAlpha = 0.3;
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.ellipse(-outerRadius, depth / 2, outerRadius * 2, outerRadius * 2 * 0.3);
            ctx.fill();
            ctx.restore();
            
            // Draw 3D sides first (back faces)
            portfolioData.forEach(function(segment, index) {
                if (segment.angleSpan < 1) return;
                
                var startRad = (segment.startAngle + rotationAngle) * Math.PI / 180;
                var endRad = (segment.startAngle + segment.angleSpan + rotationAngle) * Math.PI / 180;
                
                // Draw outer edge
                ctx.fillStyle = Qt.darker(segment.color, 1.5);
                ctx.beginPath();
                
                var steps = Math.max(2, Math.floor(segment.angleSpan / 5));
                for (var i = 0; i <= steps; i++) {
                    var angle = startRad + (endRad - startRad) * i / steps;
                    var x1 = Math.cos(angle) * outerRadius;
                    var y1 = Math.sin(angle) * outerRadius * 0.5;
                    var x2 = x1;
                    var y2 = y1 + depth;
                    
                    if (i === 0) {
                        ctx.moveTo(x1, y1);
                    }
                    ctx.lineTo(x1, y1);
                }
                
                for (var j = steps; j >= 0; j--) {
                    var angle2 = startRad + (endRad - startRad) * j / steps;
                    var x3 = Math.cos(angle2) * outerRadius;
                    var y3 = Math.sin(angle2) * outerRadius * 0.5 + depth;
                    ctx.lineTo(x3, y3);
                }
                
                ctx.closePath();
                ctx.fill();
                
                // Draw inner edge
                ctx.beginPath();
                for (var k = 0; k <= steps; k++) {
                    var angle3 = startRad + (endRad - startRad) * k / steps;
                    var x4 = Math.cos(angle3) * innerRadius;
                    var y4 = Math.sin(angle3) * innerRadius * 0.5;
                    
                    if (k === 0) {
                        ctx.moveTo(x4, y4);
                    }
                    ctx.lineTo(x4, y4);
                }
                
                for (var l = steps; l >= 0; l--) {
                    var angle4 = startRad + (endRad - startRad) * l / steps;
                    var x5 = Math.cos(angle4) * innerRadius;
                    var y5 = Math.sin(angle4) * innerRadius * 0.5 + depth;
                    ctx.lineTo(x5, y5);
                }
                
                ctx.closePath();
                ctx.fill();
            });
            
            // Draw top face
            portfolioData.forEach(function(segment, index) {
                if (segment.angleSpan < 1) return;
                
                var isHovered = index === hoverIndex;
                var scale = isHovered ? 1.05 : 1.0;
                var offsetY = isHovered ? -10 : 0;
                
                ctx.save();
                ctx.translate(0, offsetY);
                
                var startRad = (segment.startAngle + rotationAngle) * Math.PI / 180;
                var endRad = (segment.startAngle + segment.angleSpan + rotationAngle) * Math.PI / 180;
                
                // Create gradient
                var gradient = ctx.createRadialGradient(0, 0, innerRadius * scale, 0, 0, outerRadius * scale);
                gradient.addColorStop(0, Qt.lighter(segment.color, 1.3));
                gradient.addColorStop(1, segment.color);
                
                ctx.fillStyle = gradient;
                ctx.strokeStyle = Theme.border;
                ctx.lineWidth = 2;
                
                // Draw segment
                ctx.beginPath();
                ctx.arc(0, 0, outerRadius * scale, startRad, endRad);
                ctx.arc(0, 0, innerRadius * scale, endRad, startRad, true);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
                
                // Add glow for hovered segment
                if (isHovered) {
                    ctx.save();
                    ctx.shadowColor = segment.color;
                    ctx.shadowBlur = 20;
                    ctx.fill();
                    ctx.restore();
                }
                
                ctx.restore();
            });
            
            ctx.restore();
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            
            onPositionChanged: {
                var centerX = width / 2;
                var centerY = height / 2;
                var dx = mouse.x - centerX;
                var dy = mouse.y - centerY;
                var distance = Math.sqrt(dx * dx + dy * dy);
                var angle = Math.atan2(dy, dx) * 180 / Math.PI;
                angle = (angle - rotationAngle + 360) % 360;
                
                var outerRadius = width * 0.35;
                var innerRadius = outerRadius * 0.6;
                
                if (distance >= innerRadius && distance <= outerRadius) {
                    // Find which segment we're hovering
                    for (var i = 0; i < portfolioData.length; i++) {
                        var segment = portfolioData[i];
                        if (angle >= segment.startAngle && angle <= segment.startAngle + segment.angleSpan) {
                            hoverIndex = i;
                            canvas.requestPaint();
                            return;
                        }
                    }
                }
                
                hoverIndex = -1;
                canvas.requestPaint();
            }
            
            onExited: {
                hoverIndex = -1;
                canvas.requestPaint();
            }
        }
        
        Timer {
            interval: 50
            running: true
            repeat: true
            onTriggered: canvas.requestPaint()
        }
    }
    
    // Legend
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 20
        spacing: 10
        
        Repeater {
            model: portfolioData.length
            
            Rectangle {
                width: 180
                height: 40
                radius: Theme.radiusSmall
                color: hoverIndex === index ? Theme.bgCard : Theme.bgElevated
                border.color: Theme.border
                border.width: 1
                opacity: animationProgress
                
                transform: Translate {
                    x: (1 - animationProgress) * 50
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: portfolioData[index].color
                    }
                    
                    Text {
                        text: portfolioData[index].ticker
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: portfolioData[index].percentage.toFixed(1) + "%"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: hoverIndex = index
                    onExited: hoverIndex = -1
                }
            }
        }
    }
    
    // Center stats
    Column {
        anchors.centerIn: parent
        spacing: 5
        visible: portfolioData.length > 0
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Total Value"
            color: Theme.textDim
            font.pixelSize: 14
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var total = 0;
                portfolioData.forEach(function(item) {
                    total += item.value;
                });
                return "$" + total.toFixed(2);
            }
            color: Theme.accent
            font.pixelSize: 24
            font.bold: true
            
            layer.enabled: true
            layer.effect: Glow {
                radius: 8
                color: Theme.accentGlow
                samples: 16
                spread: 0.3
            }
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: portfolioData.length + " Holdings"
            color: Theme.textDim
            font.pixelSize: 12
        }
    }
    
    // Controls
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 10
        
        Button {
            text: autoRotate ? "⏸ Pause" : "▶ Play"
            onClicked: autoRotate = !autoRotate
            width: 100
            height: 30
        }
    }
}