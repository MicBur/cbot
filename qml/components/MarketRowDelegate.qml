import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string symbol: ""
    property real price: 0
    property real change: 0
    property real changePercent: 0
    property real volume: 0
    property real high: 0
    property real low: 0
    
    height: 40
    color: index % 2 === 0 ? "#333333" : "#2a2a2a"
    
    // Hover effect
    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        opacity: mouseArea.containsMouse ? 0.05 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }
    
    // Price change flash effect
    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        color: root.change > 0 ? "#4caf50" : "#f44336"
        opacity: 0
        
        function flash() {
            flashAnimation.start()
        }
        
        NumberAnimation {
            id: flashAnimation
            target: flashOverlay
            property: "opacity"
            from: 0.3
            to: 0
            duration: 500
            easing.type: Easing.OutQuad
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        
        // Symbol
        Text {
            text: root.symbol
            font.pixelSize: 14
            font.weight: Font.Bold
            color: "#ffffff"
            Layout.preferredWidth: 80
        }
        
        // Price
        Text {
            text: "$" + root.price.toFixed(2)
            font.pixelSize: 14
            color: "#ffffff"
            Layout.preferredWidth: 100
        }
        
        // Change
        Text {
            text: (root.change > 0 ? "+" : "") + root.change.toFixed(2)
            font.pixelSize: 14
            color: root.change > 0 ? "#4caf50" : (root.change < 0 ? "#f44336" : "#ffffff")
            Layout.preferredWidth: 80
        }
        
        // Change Percent
        Text {
            text: (root.changePercent > 0 ? "+" : "") + root.changePercent.toFixed(2) + "%"
            font.pixelSize: 14
            color: root.changePercent > 0 ? "#4caf50" : (root.changePercent < 0 ? "#f44336" : "#ffffff")
            Layout.preferredWidth: 80
        }
        
        // Volume
        Text {
            text: formatVolume(root.volume)
            font.pixelSize: 14
            color: "#aaaaaa"
            Layout.preferredWidth: 100
        }
        
        // High
        Text {
            text: "$" + root.high.toFixed(2)
            font.pixelSize: 14
            color: "#4caf50"
            Layout.preferredWidth: 80
        }
        
        // Low
        Text {
            text: "$" + root.low.toFixed(2)
            font.pixelSize: 14
            color: "#f44336"
            Layout.preferredWidth: 80
        }
        
        Item { Layout.fillWidth: true }
        
        // Action button
        Rectangle {
            width: 60
            height: 24
            radius: 12
            color: "#2196f3"
            opacity: mouseArea.containsMouse ? 1 : 0.7
            
            Text {
                anchors.centerIn: parent
                text: "Trade"
                font.pixelSize: 10
                color: "white"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("Trade clicked for", root.symbol)
                    // TODO: Open trading dialog
                }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            console.log("Selected symbol:", root.symbol)
            // TODO: Show detailed view or chart
        }
    }
    
    // Detect price changes and trigger flash
    onPriceChanged: {
        if (price > 0) {
            flashOverlay.flash()
        }
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