import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import QtCharts 2.15
import "../" as App

/**
 * Enhanced Candlestick Chart with animations and indicators
 */
Rectangle {
    id: root
    color: Theme.background
    
    property var chartModel: chartDataModel
    property string currentSymbol: "AAPL"
    property bool showVolume: true
    property bool showIndicators: true
    property var timeframe: "1D"
    
    // Chart header with controls
    Rectangle {
        id: chartHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: Theme.surface
        z: 10
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#40000000"
            radius: 8
            samples: 17
            verticalOffset: 2
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing3
            spacing: Theme.spacing3
            
            // Symbol info
            Column {
                Text {
                    text: root.currentSymbol
                    font: Theme.h3
                    color: Theme.textPrimary
                }
                Text {
                    text: "NASDAQ • Technology"
                    font: Theme.caption
                    color: Theme.textSecondary
                }
            }
            
            // Price info with animation
            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: "transparent"
                
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacing2
                    
                    Text {
                        id: priceText
                        text: "$156.78"
                        font: Theme.h2
                        color: Theme.textPrimary
                        
                        // Price update animation
                        Behavior on text {
                            SequentialAnimation {
                                PropertyAnimation {
                                    target: priceText
                                    property: "scale"
                                    to: 1.1
                                    duration: Theme.durationFast
                                    easing.type: Theme.easingStandard
                                }
                                PropertyAnimation {
                                    target: priceText
                                    property: "scale"
                                    to: 1.0
                                    duration: Theme.durationFast
                                    easing.type: Theme.easingStandard
                                }
                            }
                        }
                    }
                    
                    Column {
                        Text {
                            text: "+2.34"
                            font: Theme.body1
                            color: Theme.success
                        }
                        Text {
                            text: "+1.52%"
                            font: Theme.caption
                            color: Theme.success
                        }
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Timeframe selector
            Row {
                spacing: Theme.spacing1
                
                Repeater {
                    model: ["1D", "5D", "1M", "3M", "1Y", "5Y"]
                    
                    Button {
                        text: modelData
                        checkable: true
                        checked: root.timeframe === modelData
                        onClicked: root.timeframe = modelData
                        
                        background: Rectangle {
                            color: parent.checked ? Theme.primary : 
                                   (parent.hovered ? Theme.surfaceElevated : "transparent")
                            radius: Theme.radiusSmall
                            
                            Behavior on color {
                                ColorAnimation { duration: Theme.durationFast }
                            }
                        }
                    }
                }
            }
            
            // Indicator toggles
            Row {
                spacing: Theme.spacing2
                
                IndicatorToggle {
                    text: "VOL"
                    checked: root.showVolume
                    onToggled: root.showVolume = checked
                }
                
                IndicatorToggle {
                    text: "MA"
                    checked: root.showIndicators
                    onToggled: root.showIndicators = checked
                }
                
                IndicatorToggle {
                    text: "RSI"
                }
                
                IndicatorToggle {
                    text: "MACD"
                }
            }
        }
    }
    
    // Main chart area
    SplitView {
        anchors.top: chartHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Vertical
        
        // Price chart
        ChartView {
            id: priceChart
            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
            
            theme: ChartView.ChartThemeDark
            antialiasing: true
            backgroundColor: Theme.surface
            plotAreaColor: Theme.surface
            
            legend.visible: false
            margins.top: 0
            margins.bottom: 0
            margins.left: 0
            margins.right: 60
            
            // Animated grid lines
            Component.onCompleted: {
                // Custom styling for axes
                axisX.gridLineColor = Theme.alpha(Theme.textDisabled, 0.1)
                axisX.labelsColor = Theme.textSecondary
                axisX.labelsFont = Theme.caption
                
                axisY.gridLineColor = Theme.alpha(Theme.textDisabled, 0.1)
                axisY.labelsColor = Theme.textSecondary
                axisY.labelsFont = Theme.caption
            }
            
            // X-axis (time)
            DateTimeAxis {
                id: axisX
                format: "MMM dd"
                tickCount: 5
            }
            
            // Y-axis (price)
            ValueAxis {
                id: axisY
                min: 150
                max: 160
                tickCount: 6
            }
            
            // Candlestick series
            CandlestickSeries {
                id: candleSeries
                name: "Price"
                axisX: axisX
                axisY: axisY
                
                increasingColor: Theme.success
                decreasingColor: Theme.danger
                capsWidth: 0.5
                bodyWidth: 0.8
                
                // Sample data
                CandlestickSet { timestamp: new Date("2024-01-01"); open: 155; high: 157; low: 154; close: 156 }
                CandlestickSet { timestamp: new Date("2024-01-02"); open: 156; high: 158; low: 155; close: 157 }
                CandlestickSet { timestamp: new Date("2024-01-03"); open: 157; high: 159; low: 156; close: 158 }
            }
            
            // Moving averages
            LineSeries {
                id: ma20
                name: "MA20"
                axisX: axisX
                axisY: axisY
                color: Theme.info
                width: 2
                visible: root.showIndicators
                
                // Animated appearance
                opacity: visible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationNormal }
                }
                
                // Sample data
                XYPoint { x: new Date("2024-01-01").getTime(); y: 155.5 }
                XYPoint { x: new Date("2024-01-02").getTime(); y: 156.0 }
                XYPoint { x: new Date("2024-01-03").getTime(); y: 156.5 }
            }
            
            LineSeries {
                id: ma50
                name: "MA50"
                axisX: axisX
                axisY: axisY
                color: Theme.warning
                width: 2
                visible: root.showIndicators
                
                opacity: visible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationNormal }
                }
                
                // Sample data
                XYPoint { x: new Date("2024-01-01").getTime(); y: 154.5 }
                XYPoint { x: new Date("2024-01-02").getTime(); y: 155.0 }
                XYPoint { x: new Date("2024-01-03").getTime(); y: 155.5 }
            }
            
            // Crosshair on hover
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                
                property point chartPoint: Qt.point(0, 0)
                
                onPositionChanged: {
                    chartPoint = priceChart.mapToValue(Qt.point(mouseX, mouseY), candleSeries)
                    crosshairX.x = mouseX
                    crosshairY.y = mouseY
                    
                    // Update tooltip
                    var date = new Date(chartPoint.x)
                    tooltip.text = date.toLocaleDateString() + "\nPrice: $" + chartPoint.y.toFixed(2)
                    tooltip.x = mouseX + 10
                    tooltip.y = mouseY - tooltip.height - 10
                }
                
                onExited: {
                    crosshairX.visible = false
                    crosshairY.visible = false
                    tooltip.visible = false
                }
                
                onEntered: {
                    crosshairX.visible = true
                    crosshairY.visible = true
                    tooltip.visible = true
                }
            }
            
            // Crosshair lines
            Rectangle {
                id: crosshairX
                width: 1
                height: parent.height
                color: Theme.alpha(Theme.textSecondary, 0.5)
                visible: false
            }
            
            Rectangle {
                id: crosshairY
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.textSecondary, 0.5)
                visible: false
            }
            
            // Tooltip
            Rectangle {
                id: tooltip
                property alias text: tooltipText.text
                
                width: tooltipText.width + Theme.spacing3 * 2
                height: tooltipText.height + Theme.spacing2 * 2
                color: Theme.surfaceOverlay
                border.color: Theme.primary
                border.width: 1
                radius: Theme.radiusSmall
                visible: false
                
                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    font: Theme.caption
                    color: Theme.textPrimary
                }
            }
        }
        
        // Volume chart
        ChartView {
            id: volumeChart
            SplitView.preferredHeight: 150
            visible: root.showVolume
            
            theme: ChartView.ChartThemeDark
            antialiasing: true
            backgroundColor: Theme.surface
            plotAreaColor: Theme.surface
            
            legend.visible: false
            margins.top: 0
            margins.bottom: 30
            margins.left: 0
            margins.right: 60
            
            opacity: visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.durationNormal }
            }
            
            DateTimeAxis {
                id: volumeAxisX
                format: "MMM dd"
                tickCount: 5
            }
            
            ValueAxis {
                id: volumeAxisY
                min: 0
                max: 100
                tickCount: 3
                labelFormat: "%.0f M"
            }
            
            BarSeries {
                id: volumeSeries
                axisX: volumeAxisX
                axisY: volumeAxisY
                
                BarSet {
                    label: "Volume"
                    color: Theme.alpha(Theme.primary, 0.7)
                    values: [45, 62, 38]
                }
            }
        }
    }
    
    // Floating controls
    Rectangle {
        anchors.right: parent.right
        anchors.top: chartHeader.bottom
        anchors.margins: Theme.spacing3
        width: 40
        height: column.height + Theme.spacing3 * 2
        color: Theme.surfaceElevated
        radius: Theme.radiusSmall
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#40000000"
            radius: 8
            samples: 17
            horizontalOffset: 0
            verticalOffset: 2
        }
        
        Column {
            id: column
            anchors.centerIn: parent
            spacing: Theme.spacing2
            
            ChartToolButton {
                icon: "+"
                tooltip: "Zoom in"
                onClicked: priceChart.zoomIn()
            }
            
            ChartToolButton {
                icon: "-"
                tooltip: "Zoom out"
                onClicked: priceChart.zoomOut()
            }
            
            ChartToolButton {
                icon: "⟲"
                tooltip: "Reset zoom"
                onClicked: priceChart.zoomReset()
            }
            
            Rectangle {
                width: parent.width - Theme.spacing2 * 2
                height: 1
                color: Theme.textDisabled
                opacity: 0.3
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            ChartToolButton {
                icon: "📷"
                tooltip: "Screenshot"
                onClicked: console.log("Take screenshot")
            }
            
            ChartToolButton {
                icon: "⚙"
                tooltip: "Settings"
                onClicked: console.log("Open settings")
            }
        }
    }
}

// Indicator toggle component
component IndicatorToggle : Rectangle {
    property alias text: label.text
    property bool checked: false
    signal toggled(bool checked)
    
    width: label.width + Theme.spacing3 * 2
    height: 32
    radius: Theme.radiusSmall
    color: checked ? Theme.primary : "transparent"
    border.color: checked ? Theme.primary : Theme.textDisabled
    border.width: 1
    
    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }
    
    Text {
        id: label
        anchors.centerIn: parent
        font: Theme.caption
        font.weight: Font.Bold
        color: parent.checked ? Theme.textPrimary : Theme.textSecondary
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: {
            parent.checked = !parent.checked
            parent.toggled(parent.checked)
        }
    }
}

// Chart tool button component
component ChartToolButton : Rectangle {
    property alias icon: iconText.text
    property alias tooltip: toolTip.text
    signal clicked()
    
    width: 32
    height: 32
    radius: Theme.radiusSmall
    color: mouseArea.containsMouse ? Theme.surfaceOverlay : "transparent"
    
    Text {
        id: iconText
        anchors.centerIn: parent
        font.pixelSize: 16
        color: Theme.textPrimary
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
    
    ToolTip {
        id: toolTip
        visible: mouseArea.containsMouse
        delay: 500
    }
}