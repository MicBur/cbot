import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Frontend 1.0

Item {
    id: root
    
    property var grokModel: grokDeepSearchModel // From context
    property string selectedTicker: ""
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
    
    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgCard }
            GradientStop { position: 0.5; color: Theme.bg }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.accentDark.r, Theme.accentDark.g, Theme.accentDark.b, 0.1) }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Column {
                Text {
                    text: "Grok AI Deep Analysis"
                    color: Theme.accent
                    font.pixelSize: 28
                    font.bold: true
                    
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 10
                        color: Theme.accentGlow
                        samples: 20
                        spread: 0.3
                    }
                }
                
                Text {
                    text: "AI-powered stock recommendations with ML confidence scores"
                    color: Theme.textDim
                    font.pixelSize: 14
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Refresh button
            Button {
                text: "🔄 Refresh"
                onClicked: {
                    refreshAnimation.start()
                    // Trigger refresh in backend
                }
                
                RotationAnimation {
                    id: refreshAnimation
                    target: parent
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }
        
        // Main content grid
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 320
            cellHeight: 380
            clip: true
            
            model: grokModel
            
            delegate: Rectangle {
                id: card
                width: 300
                height: 360
                radius: Theme.radiusLarge
                color: Theme.bgCard
                border.color: mouseArea.containsMouse ? Theme.accent : Theme.border
                border.width: 2
                
                property real cardProgress: 0
                property bool isRecommendedBuy: recommendedAction === "BUY"
                property real confidenceLevel: mlConfidence || 0.5
                
                Component.onCompleted: {
                    cardAnimation.delay = index * 100
                    cardAnimation.start()
                }
                
                NumberAnimation {
                    id: cardAnimation
                    target: card
                    property: "cardProgress"
                    from: 0
                    to: 1
                    duration: Theme.durMed
                    easing.type: Easing.OutBack
                }
                
                transform: [
                    Scale {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        xScale: 0.8 + 0.2 * cardProgress
                        yScale: 0.8 + 0.2 * cardProgress
                    },
                    Translate {
                        y: (1 - cardProgress) * 50
                    }
                ]
                
                opacity: cardProgress
                
                // Glow effect for high confidence
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    visible: confidenceLevel > 0.8
                    
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 20 * confidenceLevel
                        color: isRecommendedBuy ? Theme.successGlow : Theme.warningGlow
                        samples: 32
                        spread: 0.3
                        
                        SequentialAnimation on radius {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { from: 15; to: 25; duration: 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 25; to: 15; duration: 2000; easing.type: Easing.InOutSine }
                        }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selectedTicker = ticker
                        selectionAnimation.start()
                    }
                }
                
                // Selection pulse
                Rectangle {
                    id: selectionPulse
                    anchors.fill: parent
                    radius: parent.radius
                    color: Theme.accent
                    opacity: 0
                    
                    SequentialAnimation {
                        id: selectionAnimation
                        NumberAnimation { target: selectionPulse; property: "opacity"; from: 0; to: 0.3; duration: 200 }
                        NumberAnimation { target: selectionPulse; property: "opacity"; from: 0.3; to: 0; duration: 400 }
                    }
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    // Header with ticker and score
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: ticker
                            color: Theme.text
                            font.pixelSize: 24
                            font.bold: true
                            font.family: "Consolas, Monaco, monospace"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Score badge
                        Rectangle {
                            width: 60
                            height: 30
                            radius: 15
                            color: {
                                if (score > 0.8) return Theme.success
                                if (score > 0.6) return Theme.warning
                                return Theme.danger
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: (score * 100).toFixed(0) + "%"
                                color: Theme.bg
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                    }
                    
                    // Analysis text
                    Text {
                        Layout.fillWidth: true
                        text: analysis || "Analysis pending..."
                        color: Theme.text
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    
                    // Metrics row
                    Row {
                        spacing: 8
                        
                        Repeater {
                            model: [
                                { label: "Sentiment", value: sentimentScore, color: Theme.accent },
                                { label: "Technical", value: technicalScore, color: Theme.accentAlt },
                                { label: "ML Conf", value: mlConfidence, color: Theme.warning }
                            ]
                            
                            delegate: Column {
                                spacing: 2
                                
                                Text {
                                    text: modelData.label
                                    color: Theme.textDim
                                    font.pixelSize: 10
                                }
                                
                                Rectangle {
                                    width: 80
                                    height: 6
                                    radius: 3
                                    color: Theme.bgElevated
                                    
                                    Rectangle {
                                        width: parent.width * modelData.value
                                        height: parent.height
                                        radius: parent.radius
                                        color: modelData.color
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: Theme.durMed }
                                        }
                                    }
                                }
                                
                                Text {
                                    text: (modelData.value * 100).toFixed(0) + "%"
                                    color: Theme.textDim
                                    font.pixelSize: 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.border
                        opacity: 0.5
                    }
                    
                    // Target price and action
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Column {
                            Text {
                                text: "7-Day Target"
                                color: Theme.textDim
                                font.pixelSize: 10
                            }
                            Text {
                                text: "$" + (targetPrice7d || 0).toFixed(2)
                                color: Theme.accent
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Action button
                        Rectangle {
                            width: 80
                            height: 36
                            radius: 18
                            color: isRecommendedBuy ? Theme.success : Theme.danger
                            
                            Text {
                                anchors.centerIn: parent
                                text: recommendedAction || "HOLD"
                                color: Theme.bg
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            SequentialAnimation on scale {
                                running: isRecommendedBuy && confidenceLevel > 0.8
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 1.1; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.1; to: 1; duration: 1000; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                    
                    // Reasons
                    Column {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: "Key Factors:"
                            color: Theme.textDim
                            font.pixelSize: 11
                            font.bold: true
                        }
                        
                        Repeater {
                            model: reasons ? reasons.slice(0, 2) : []
                            
                            Row {
                                spacing: 6
                                
                                Text {
                                    text: "✓"
                                    color: Theme.success
                                    font.pixelSize: 10
                                }
                                
                                Text {
                                    text: modelData
                                    color: Theme.text
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                    width: card.width - 60
                                }
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    // Weight recommendation
                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        radius: 12
                        color: Theme.bgElevated
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            
                            Text {
                                text: "Portfolio Weight:"
                                color: Theme.textDim
                                font.pixelSize: 10
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Text {
                                text: ((recommendedWeight || 0) * 100).toFixed(0) + "%"
                                color: Theme.accent
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // No data state
    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 200
        radius: Theme.radiusLarge
        color: Theme.bgCard
        visible: !grokModel || grokModel.rowCount() === 0
        
        Column {
            anchors.centerIn: parent
            spacing: 12
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "🤖"
                font.pixelSize: 48
                opacity: 0.5
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No Grok analysis available"
                color: Theme.textDim
                font.pixelSize: 18
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Deep search AI analysis will appear here"
                color: Theme.textDim
                font.pixelSize: 12
            }
        }
    }
}