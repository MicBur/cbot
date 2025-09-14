import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../" as App

/**
 * Enhanced Market List with animations and better UX
 */
Rectangle {
    id: root
    color: Theme.background
    
    // Properties
    property var model: marketModel
    property string filterText: ""
    property bool showOnlyWatchlist: false
    property bool realTimeUpdates: true
    
    // Header with search and controls
    Rectangle {
        id: header
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
            
            // Search input with icon
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Theme.radiusSmall
                color: Theme.surfaceElevated
                border.color: searchField.focus ? Theme.primary : "transparent"
                border.width: 2
                
                Behavior on border.color {
                    ColorAnimation { duration: Theme.durationFast }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing2
                    spacing: Theme.spacing2
                    
                    // Search icon
                    Text {
                        text: "🔍"
                        font.pixelSize: 16
                        color: Theme.textSecondary
                    }
                    
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search symbols..."
                        font: Theme.body2
                        color: Theme.textPrimary
                        background: Item {}
                        
                        onTextChanged: root.filterText = text
                    }
                    
                    // Clear button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: clearMouseArea.containsMouse ? Theme.dangerLight : Theme.danger
                        visible: searchField.text.length > 0
                        
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.pixelSize: 14
                            color: "white"
                        }
                        
                        MouseArea {
                            id: clearMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: searchField.clear()
                        }
                        
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.durationFast }
                        }
                    }
                }
            }
            
            // Filter buttons
            Button {
                text: "Watchlist"
                checkable: true
                checked: root.showOnlyWatchlist
                onToggled: root.showOnlyWatchlist = checked
            }
            
            Button {
                text: "Live"
                checkable: true
                checked: root.realTimeUpdates
                onToggled: root.realTimeUpdates = checked
            }
        }
    }
    
    // Market statistics bar
    Rectangle {
        id: statsBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: Theme.surfaceElevated
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing2
            spacing: Theme.spacing4
            
            // Market stats
            StatItem {
                label: "Total"
                value: model ? model.count : 0
                color: Theme.textSecondary
            }
            
            StatItem {
                label: "Gainers"
                value: model ? model.gainersCount : 0
                color: Theme.success
            }
            
            StatItem {
                label: "Losers"
                value: model ? model.losersCount : 0
                color: Theme.danger
            }
            
            Item { Layout.fillWidth: true }
            
            // Sort controls
            ComboBox {
                id: sortCombo
                model: ["Symbol", "Price", "Change %", "Volume"]
                font: Theme.caption
            }
        }
    }
    
    // Main list view
    ListView {
        id: listView
        anchors.top: statsBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        
        model: root.model
        clip: true
        spacing: 1
        
        // Smooth scrolling
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        
        // Pull to refresh
        property bool refreshing: false
        property real pullDistance: 0
        
        onContentYChanged: {
            if (contentY < -80 && !refreshing) {
                refreshing = true
                refreshTimer.start()
            }
            pullDistance = Math.max(0, -contentY)
        }
        
        Timer {
            id: refreshTimer
            interval: 1000
            onTriggered: {
                listView.refreshing = false
                // Trigger data refresh
                poller.triggerNow()
            }
        }
        
        // Refresh indicator
        Rectangle {
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40
            radius: 20
            color: Theme.primary
            opacity: listView.pullDistance / 100
            visible: opacity > 0
            
            rotation: listView.pullDistance * 3
            
            Text {
                anchors.centerIn: parent
                text: "↻"
                font.pixelSize: 20
                color: "white"
            }
            
            Behavior on rotation {
                NumberAnimation { duration: Theme.durationFast }
            }
        }
        
        delegate: MarketListDelegate {
            width: listView.width
            symbol: model.symbol || ""
            price: model.price || 0
            change: model.change || 0
            changePercent: model.changePercent || 0
            volume: model.volume || 0
            direction: model.direction || 0
            
            onClicked: {
                // Handle symbol selection
                console.log("Selected symbol:", symbol)
            }
        }
        
        // Empty state
        Item {
            anchors.fill: parent
            visible: listView.count === 0
            
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing3
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📊"
                    font.pixelSize: 48
                    opacity: 0.3
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchField.text ? "No results found" : "No market data"
                    font: Theme.h4
                    color: Theme.textSecondary
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchField.text ? "Try a different search" : "Waiting for data..."
                    font: Theme.body2
                    color: Theme.textDisabled
                }
            }
        }
        
        // Loading overlay
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.background, 0.8)
            visible: model && model.loading
            
            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
            }
        }
    }
    
    // Component for stat items
    component StatItem : Row {
        property string label
        property var value
        property color color: Theme.textPrimary
        
        spacing: Theme.spacing1
        
        Text {
            text: label + ":"
            font: Theme.caption
            color: Theme.textSecondary
        }
        
        Text {
            text: value.toString()
            font: Theme.caption
            font.weight: Font.Bold
            color: parent.color
        }
    }
}

// Enhanced market list delegate
component MarketListDelegate : Rectangle {
    id: delegate
    
    property string symbol
    property real price
    property real change
    property real changePercent
    property real volume
    property int direction
    
    signal clicked()
    
    height: 60
    color: mouseArea.containsMouse ? Theme.surfaceElevated : Theme.surface
    
    // Smooth hover transition
    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }
    
    // Price change animation
    Rectangle {
        id: changeIndicator
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: direction > 0 ? Theme.success : (direction < 0 ? Theme.danger : Theme.textDisabled)
        
        // Pulse animation on update
        SequentialAnimation {
            id: pulseAnimation
            NumberAnimation {
                target: changeIndicator
                property: "opacity"
                from: 1
                to: 0.3
                duration: Theme.durationFast
            }
            NumberAnimation {
                target: changeIndicator
                property: "opacity"
                to: 1
                duration: Theme.durationFast
            }
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing3
        anchors.rightMargin: Theme.spacing3
        spacing: Theme.spacing3
        
        // Symbol and exchange
        Column {
            Layout.preferredWidth: 80
            
            Text {
                text: delegate.symbol
                font: Theme.body1
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
            
            Text {
                text: "NASDAQ" // Could be dynamic
                font: Theme.caption
                color: Theme.textSecondary
            }
        }
        
        // Price
        Text {
            Layout.preferredWidth: 100
            text: "$" + delegate.price.toFixed(2)
            font: Theme.body1
            font.family: Theme.mono.family
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignRight
        }
        
        // Change
        Rectangle {
            Layout.preferredWidth: 120
            Layout.fillHeight: true
            radius: Theme.radiusSmall
            color: direction > 0 ? Theme.alpha(Theme.success, 0.1) : 
                   (direction < 0 ? Theme.alpha(Theme.danger, 0.1) : "transparent")
            
            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.spacing1
                
                Text {
                    text: direction > 0 ? "▲" : (direction < 0 ? "▼" : "—")
                    font.pixelSize: 12
                    color: direction > 0 ? Theme.success : (direction < 0 ? Theme.danger : Theme.textSecondary)
                }
                
                Text {
                    text: (delegate.change >= 0 ? "+" : "") + delegate.change.toFixed(2)
                    font: Theme.body2
                    font.family: Theme.mono.family
                    color: direction > 0 ? Theme.success : (direction < 0 ? Theme.danger : Theme.textSecondary)
                }
                
                Text {
                    text: "(" + (delegate.changePercent >= 0 ? "+" : "") + delegate.changePercent.toFixed(2) + "%)"
                    font: Theme.caption
                    color: direction > 0 ? Theme.success : (direction < 0 ? Theme.danger : Theme.textSecondary)
                }
            }
        }
        
        Item { Layout.fillWidth: true }
        
        // Volume
        Column {
            Layout.preferredWidth: 100
            horizontalAlignment: Text.AlignRight
            
            Text {
                text: formatVolume(delegate.volume)
                font: Theme.body2
                color: Theme.textPrimary
            }
            
            // Mini volume bar
            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surfaceOverlay
                
                Rectangle {
                    width: parent.width * Math.min(1, delegate.volume / 10000000) // Normalized to 10M
                    height: parent.height
                    radius: parent.radius
                    color: Theme.primary
                }
            }
        }
        
        // Action buttons
        Row {
            spacing: Theme.spacing2
            
            IconButton {
                icon: "⭐"
                tooltip: "Add to watchlist"
                onClicked: console.log("Add to watchlist:", delegate.symbol)
            }
            
            IconButton {
                icon: "📈"
                tooltip: "View chart"
                onClicked: console.log("View chart:", delegate.symbol)
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: delegate.clicked()
    }
    
    // Update animation
    Connections {
        target: model
        function onDataChanged() {
            pulseAnimation.start()
        }
    }
    
    // Helper function
    function formatVolume(vol) {
        if (vol >= 1000000000) return (vol / 1000000000).toFixed(1) + "B"
        if (vol >= 1000000) return (vol / 1000000).toFixed(1) + "M"
        if (vol >= 1000) return (vol / 1000).toFixed(1) + "K"
        return vol.toFixed(0)
    }
}

// Icon button component
component IconButton : Rectangle {
    property string icon
    property string tooltip
    signal clicked()
    
    width: 32
    height: 32
    radius: 16
    color: iconMouseArea.containsMouse ? Theme.surfaceOverlay : "transparent"
    
    Text {
        anchors.centerIn: parent
        text: icon
        font.pixelSize: 16
    }
    
    MouseArea {
        id: iconMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
    
    ToolTip.visible: iconMouseArea.containsMouse
    ToolTip.text: tooltip
    ToolTip.delay: 500
}