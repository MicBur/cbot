import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

/*
  Enhanced Market List with modern animations and effects
*/
Item {
    id: root
    
    property var model: marketModel
    property real animationProgress: 0
    
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
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        
        // Animated gradient background
        LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, 0)
            end: Qt.point(width, height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.05) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.accentAlt.r, Theme.accentAlt.g, Theme.accentAlt.b, 0.05) }
            }
            
            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 0.7; duration: 3000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.7; to: 0.3; duration: 3000; easing.type: Easing.InOutSine }
            }
        }
    }
    
    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 10
        model: marketModel
        spacing: 8
        clip: true
        
        delegate: Rectangle {
            id: delegateItem
            width: ListView.view.width
            height: 80
            radius: Theme.radius
            color: mouseArea.containsMouse ? Theme.bgCard : Theme.bgElevated
            border.color: Theme.border
            border.width: 1
            
            property real itemProgress: 0
            property bool isPositive: change >= 0
            property real changeIntensity: Math.min(1.0, Math.abs(changePercent) / 5.0)
            
            // Staggered appearance animation
            Component.onCompleted: {
                appearAnimation.delay = index * 50;
                appearAnimation.start();
            }
            
            NumberAnimation {
                id: appearAnimation
                target: delegateItem
                property: "itemProgress"
                from: 0
                to: 1
                duration: Theme.durMed
                easing.type: Easing.OutBack
            }
            
            transform: [
                Scale {
                    origin.x: delegateItem.width / 2
                    origin.y: delegateItem.height / 2
                    xScale: 0.9 + 0.1 * itemProgress
                    yScale: 0.9 + 0.1 * itemProgress
                },
                Translate {
                    x: (1 - itemProgress) * 50
                }
            ]
            
            opacity: itemProgress
            
            // Glow effect for high movers
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                visible: changeIntensity > 0.5
                
                layer.enabled: true
                layer.effect: Glow {
                    radius: 10 * changeIntensity
                    color: isPositive ? Theme.successGlow : Theme.dangerGlow
                    samples: 16
                    spread: 0.3
                    
                    SequentialAnimation on radius {
                        running: changeIntensity > 0.8
                        loops: Animation.Infinite
                        NumberAnimation { from: 8; to: 15; duration: 1000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 15; to: 8; duration: 1000; easing.type: Easing.InOutSine }
                    }
                }
            }
            
            // Glass overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.bgGlass
                opacity: mouseArea.containsMouse ? 0.3 : 0.1
                
                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    poller.currentSymbol = ticker;
                    pulseAnimation.start();
                }
            }
            
            // Click pulse animation
            Rectangle {
                id: pulseCircle
                anchors.centerIn: parent
                width: 0
                height: 0
                radius: width / 2
                color: Theme.accent
                opacity: 0
                
                ParallelAnimation {
                    id: pulseAnimation
                    NumberAnimation { target: pulseCircle; property: "width"; from: 0; to: parent.width * 2; duration: 400; easing.type: Easing.OutQuad }
                    NumberAnimation { target: pulseCircle; property: "height"; from: 0; to: parent.height * 2; duration: 400; easing.type: Easing.OutQuad }
                    NumberAnimation { target: pulseCircle; property: "opacity"; from: 0.3; to: 0; duration: 400; easing.type: Easing.OutQuad }
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12
                
                // Symbol column with animated badge
                Column {
                    Layout.preferredWidth: 80
                    spacing: 4
                    
                    Text {
                        text: ticker
                        color: Theme.text
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Consolas, Monaco, monospace"
                    }
                    
                    // Rank badge
                    Rectangle {
                        width: 30
                        height: 20
                        radius: Theme.radiusSmall
                        color: index < 3 ? Theme.accent : Theme.bgCard
                        border.color: Theme.border
                        visible: index < 10
                        
                        Text {
                            anchors.centerIn: parent
                            text: "#" + (index + 1)
                            color: index < 3 ? Theme.bg : Theme.textDim
                            font.pixelSize: 10
                            font.bold: true
                        }
                        
                        RotationAnimation on rotation {
                            from: -5
                            to: 5
                            duration: 2000
                            loops: Animation.Infinite
                            running: index === 0
                            easing.type: Easing.InOutSine
                        }
                    }
                }
                
                // Price column with live update effect
                Column {
                    Layout.preferredWidth: 100
                    spacing: 2
                    
                    Text {
                        id: priceText
                        text: "$" + Number(price).toFixed(2)
                        color: Theme.text
                        font.pixelSize: 20
                        font.bold: true
                        
                        property real lastPrice: price
                        property color flashColor: Theme.text
                        
                        onTextChanged: {
                            if (price > lastPrice) {
                                flashColor = Theme.success;
                            } else if (price < lastPrice) {
                                flashColor = Theme.danger;
                            }
                            flashAnimation.restart();
                            lastPrice = price;
                        }
                        
                        ColorAnimation {
                            id: flashAnimation
                            target: priceText
                            property: "color"
                            from: priceText.flashColor
                            to: Theme.text
                            duration: 600
                            easing.type: Easing.OutQuad
                        }
                    }
                    
                    Text {
                        text: "Vol: " + (volume ? (volume / 1000000).toFixed(1) + "M" : "---")
                        color: Theme.textDim
                        font.pixelSize: 11
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Change column with animated indicators
                Column {
                    Layout.preferredWidth: 120
                    spacing: 4
                    
                    // Change value
                    RowLayout {
                        spacing: 6
                        
                        // Direction arrow with animation
                        Text {
                            text: isPositive ? "▲" : "▼"
                            color: isPositive ? Theme.success : Theme.danger
                            font.pixelSize: 16
                            
                            SequentialAnimation on opacity {
                                running: Math.abs(changePercent) > 3
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.5; to: 1; duration: 500 }
                                NumberAnimation { from: 1; to: 0.5; duration: 500 }
                            }
                        }
                        
                        Text {
                            text: (isPositive ? "+" : "") + Number(change).toFixed(2)
                            color: isPositive ? Theme.success : Theme.danger
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                    
                    // Percentage badge
                    Rectangle {
                        width: percentText.implicitWidth + 16
                        height: 24
                        radius: Theme.radiusSmall
                        color: isPositive ? Theme.success : Theme.danger
                        opacity: 0.9
                        
                        Text {
                            id: percentText
                            anchors.centerIn: parent
                            text: (isPositive ? "+" : "") + Number(changePercent).toFixed(2) + "%"
                            color: Theme.bg
                            font.pixelSize: 12
                            font.bold: true
                        }
                        
                        // Pulse for high movers
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.color: parent.color
                            border.width: 2
                            opacity: 0
                            
                            SequentialAnimation on opacity {
                                running: Math.abs(changePercent) > 5
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: 0.6; duration: 1000; easing.type: Easing.OutQuad }
                                NumberAnimation { from: 0.6; to: 0; duration: 1000; easing.type: Easing.InQuad }
                            }
                            
                            NumberAnimation on scale {
                                running: Math.abs(changePercent) > 5
                                loops: Animation.Infinite
                                from: 1
                                to: 1.2
                                duration: 2000
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
                
                // Sparkline preview (mini chart)
                Canvas {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 30
                    opacity: 0.7
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        
                        // Generate random mini chart data
                        var points = 20;
                        var data = [];
                        var base = 100;
                        for (var i = 0; i < points; i++) {
                            base += (Math.random() - 0.5) * 5;
                            data.push(base);
                        }
                        
                        var min = Math.min(...data);
                        var max = Math.max(...data);
                        var range = max - min;
                        
                        ctx.strokeStyle = isPositive ? Theme.success : Theme.danger;
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        
                        for (var j = 0; j < data.length; j++) {
                            var x = (j / (data.length - 1)) * width;
                            var y = height - ((data[j] - min) / range) * height;
                            
                            if (j === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        
                        ctx.stroke();
                        
                        // Fill gradient
                        var gradient = ctx.createLinearGradient(0, 0, 0, height);
                        gradient.addColorStop(0, Qt.rgba(isPositive ? Theme.success.r : Theme.danger.r, 
                                                       isPositive ? Theme.success.g : Theme.danger.g,
                                                       isPositive ? Theme.success.b : Theme.danger.b, 0.3));
                        gradient.addColorStop(1, "transparent");
                        
                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height);
                        ctx.closePath();
                        ctx.fillStyle = gradient;
                        ctx.fill();
                    }
                    
                    Component.onCompleted: requestPaint()
                    
                    Timer {
                        interval: 3000 + Math.random() * 2000
                        running: true
                        repeat: true
                        onTriggered: parent.requestPaint()
                    }
                }
            }
        }
        
        // Scroll indicator
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 8
            
            contentItem: Rectangle {
                radius: 4
                color: Theme.accent
                opacity: 0.5
            }
        }
    }
    
    // No data placeholder
    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 100
        radius: Theme.radius
        color: Theme.bgCard
        visible: !model || model.rowCount() === 0
        
        Text {
            anchors.centerIn: parent
            text: "No market data"
            color: Theme.textDim
            font.pixelSize: 16
        }
    }
}