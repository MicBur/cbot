import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Frontend 1.0

ListView {
    id: list
    model: marketModel
    clip: true
    // Ausgewähltes Symbol (synchron mit Poller)
    property string selectedSymbol: poller ? poller.currentSymbol : ""
    Connections {
        target: poller
        function onCurrentSymbolChanged() { list.selectedSymbol = poller.currentSymbol }
    }
    delegate: Rectangle {
        id: rowRoot
        width: ListView.view.width
        height: 50
        color: symbol === list.selectedSymbol ? Theme.accentAlt : (index % 2 === 0 ? Theme.bgElevated : Theme.bg)
        border.color: symbol === list.selectedSymbol ? Theme.accent : "transparent"
        border.width: symbol === list.selectedSymbol ? 1 : 0
        property int dir: direction
        property double displayPrice: price
        property double displayChange: change
        property double displayChangePercent: changePercent
        // Sparkline Buffer
        property var priceBuffer: []
        property int maxPoints: 40
        function pushPrice(p) {
            if (priceBuffer.length === 0 || priceBuffer[priceBuffer.length-1] !== p) {
                priceBuffer.push(p)
                if (priceBuffer.length > maxPoints) priceBuffer.shift()
                sparkCanvas.requestPaint()
            }
        }
        Rectangle { id: flash; anchors.fill: parent; color: "transparent"; z: -1 }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 12
            Text { text: symbol; color: Theme.text; font.pixelSize: 14; width: 80; font.bold: true }
            Text { text: Number(displayPrice).toFixed(2); color: Theme.text; font.family: "Consolas"; width: 70 }
            Text { text: (displayChange > 0 ? "+" : "") + Number(displayChange).toFixed(2); color: dir > 0 ? Theme.success : (dir < 0 ? Theme.danger : Theme.textDim); width: 70 }
            Text { text: Number(displayChangePercent).toFixed(2) + "%"; color: dir > 0 ? Theme.success : (dir < 0 ? Theme.danger : Theme.textDim); width: 60 }
            // Sparkline Container
            Item { width: 80; height: parent.height-8
                Canvas {
                    id: sparkCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext('2d')
                        ctx.reset()
                        ctx.fillStyle = 'transparent'
                        ctx.fillRect(0,0,width,height)
                        var arr = rowRoot.priceBuffer
                        if (!arr || arr.length < 2) return
                        var min = Math.min.apply(Math, arr)
                        var max = Math.max.apply(Math, arr)
                        var range = max-min; if (range === 0) range = 1
                        ctx.lineWidth = 1.2
                        ctx.strokeStyle = rowRoot.dir>0 ? Theme.success : (rowRoot.dir<0 ? Theme.danger : Theme.accentAlt)
                        ctx.beginPath()
                        for (var i=0;i<arr.length;i++) {
                            var x = (i/(arr.length-1)) * (width-2) + 1
                            var y = height - ((arr[i]-min)/range) * (height-2) - 1
                            if (i===0) {
                                ctx.moveTo(x,y)
                            } else {
                                ctx.lineTo(x,y)
                            }
                        }
                        ctx.stroke()
                        // Gradient fill (light)
                        var grad = ctx.createLinearGradient(0,0,0,height)
                        grad.addColorStop(0, rowRoot.dir>0 ? Theme.success + '55' : (rowRoot.dir<0 ? Theme.danger + '55' : Theme.accentAlt + '33'))
                        grad.addColorStop(1, '#00000000')
                        ctx.fillStyle = grad
                        ctx.lineTo(width-1,height-1)
                        ctx.lineTo(1,height-1)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; color: "transparent" }
        }
        states: [
            State { name: "up"; when: dir > 0 },
            State { name: "down"; when: dir < 0 },
            State { name: "flat"; when: dir === 0 }
        ]
        transitions: [
            Transition {
                ColorAnimation { properties: "color"; duration: Theme.durMed }
            }
        ]
        Connections {
            target: marketModel
            function onRowAnimated(r) {
                if (r === index) {
                    flashAnim.restart()
                    priceAnim.from = rowRoot.displayPrice
                    priceAnim.to = price
                    priceAnim.restart()
                    changeAnim.from = rowRoot.displayChange
                    changeAnim.to = change
                    changeAnim.restart()
                    changePctAnim.from = rowRoot.displayChangePercent
                    changePctAnim.to = changePercent
                    changePctAnim.restart()
                    rowRoot.pushPrice(price)
                }
            }
        }
        Component.onCompleted: pushPrice(price)
        ColorAnimation { id: flashAnim; target: flash; property: "color"; from: dir>0?"#062b1a":"#3a0d11"; to: "transparent"; duration: 480; easing.type: Easing.OutQuad }
        NumberAnimation { id: priceAnim; target: rowRoot; property: "displayPrice"; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { id: changeAnim; target: rowRoot; property: "displayChange"; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { id: changePctAnim; target: rowRoot; property: "displayChangePercent"; duration: 300; easing.type: Easing.OutCubic }
        // Auswahl / Klick
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (poller && poller.currentSymbol !== symbol) {
                    poller.currentSymbol = symbol
                    list.selectedSymbol = symbol
                    // Falls eine sofortige Poll-Methode existiert, auslösen (defensiv geprüft)
                    if (poller.triggerNow) {
                        poller.triggerNow()
                    } else if (poller.pollNow) {
                        poller.pollNow()
                    }
                }
            }
        }
    }
}
