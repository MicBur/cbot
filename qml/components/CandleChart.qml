import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Frontend 1.0

/*
  CandleChart Placeholder
  - Verwendet Canvas für einfache Candlesticks (Mock Daten falls keine reale Serie übergeben)
  - Prognose Linie (gepunktet) überlagert
  Später: Anbindung an Redis Keys z.B. chart_data_<TICKER>, predictions_<TICKER>
*/
Item {
    id: root
    property var candles: [] // Erwartet Array von Objekten {t: <string|number>, o,h,l,c}
    property var forecast: [] // Array von {t, v}
    property color bullColor: Theme.success
    property color bearColor: Theme.danger
    property color wickColor: Theme.textDim
    property int maxCandles: 120
    property string currentTicker: poller ? poller.currentSymbol : "AAPL"
    property bool useMock: candles.length === 0

    // Neue Properties für echte Modelle
    property var modelCandles: chartDataModel // ChartDataModel aus Context
    property var modelForecast: predictionsModel // PredictionsModel
    property bool hasRealData: modelCandles && modelCandles.rowCount() > 0
    onHasRealDataChanged: if (hasRealData) useMock = false

    implicitHeight: 300

    // Zentrale abgeleitete Werte (on-demand Funktionen, um Inline-Ausdrücke zu reduzieren)
    function lastClose() {
        if (hasRealData && modelCandles.rowCount()>0) {
            var i = modelCandles.rowCount()-1; return modelCandles.data(modelCandles.index(i,0), modelCandles.CloseRole);
        } else if (candles.length>0) { return candles[candles.length-1].c; }
        return undefined;
    }
    function prevClose() {
        if (hasRealData && modelCandles.rowCount()>1) {
            var i = modelCandles.rowCount()-2; return modelCandles.data(modelCandles.index(i,0), modelCandles.CloseRole);
        } else if (candles.length>1) { return candles[candles.length-2].c; }
        return undefined;
    }
    function changeAbs() {
        var c = lastClose(); var p = prevClose(); if (c===undefined || p===undefined) return undefined; return c - p;
    }
    function changePct() {
        var c = lastClose(); var p = prevClose(); if (c===undefined || p===undefined || p===0) return undefined; return (c-p)/p*100;
    }
    function lastForecast() {
        if (modelForecast && modelForecast.rowCount()>0) {
            return modelForecast.data(modelForecast.index(modelForecast.rowCount()-1,0), modelForecast.ValueRole);
        } else if (forecast.length>0) {
            return forecast[forecast.length-1].v;
        }
        return undefined;
    }
    function forecastDiffAbs() {
        var f = lastForecast(); var c = lastClose(); if (f===undefined || c===undefined) return undefined; return f - c;
    }
    function forecastDiffPct() {
        var f = lastForecast(); var c = lastClose(); if (f===undefined || c===undefined || c===0) return undefined; return (f-c)/c*100;
    }

    // Mock Daten generieren
    function ensureMock() {
        if (!useMock) return;
        var arr = [];
        var base = 150 + Math.random()*10;
        for (var i=0;i<80;i++) {
            var o = base + (Math.random()-0.5)*2;
            var c = o + (Math.random()-0.5)*4;
            var h = Math.max(o,c) + Math.random()*2;
            var l = Math.min(o,c) - Math.random()*2;
            arr.push({t:i,o:o,h:h,l:l,c:c});
            base = c;
        }
        candles = arr;
        var f=[]; var last=arr[arr.length-1].c; for (var j=1;j<=20;j++) { last += (Math.random()-0.4)*1.2; f.push({t:arr.length-1 + j, v:last}); }
        forecast = f;
    }

    Component.onCompleted: ensureMock()

    Rectangle { anchors.fill: parent; color: Theme.bgElevated; border.color: Theme.accentAlt; border.width: 1; radius: 4 }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Theme.bgElevated;
            ctx.fillRect(0,0,width,height);
            var data = [];
            if (hasRealData) {
                // baue Array aus modelCandles Rollen
                for (var i=0;i<modelCandles.rowCount();i++) {
                    var o = modelCandles.data(modelCandles.index(i,0), modelCandles.OpenRole);
                    var h = modelCandles.data(modelCandles.index(i,0), modelCandles.HighRole);
                    var l = modelCandles.data(modelCandles.index(i,0), modelCandles.LowRole);
                    var c = modelCandles.data(modelCandles.index(i,0), modelCandles.CloseRole);
                    var t = modelCandles.data(modelCandles.index(i,0), modelCandles.TimeRole);
                    data.push({o:o,h:h,l:l,c:c,t:t});
                }
            } else {
                data = candles;
            }
            // Forecast real
            var fc = [];
            if (modelForecast && modelForecast.rowCount() > 0) {
                for (var f=0; f<modelForecast.rowCount(); f++) {
                    var t = modelForecast.data(modelForecast.index(f,0), modelForecast.TimeRole);
                    var v = modelForecast.data(modelForecast.index(f,0), modelForecast.ValueRole);
                    fc.push({t:t,v:v});
                }
            } else {
                fc = forecast;
            }
            if (!data || data.length === 0) return;
            var visible = data.slice(-maxCandles);
            var w = width; var h = height; var padL=50; var padR=10; var padT=10; var padB=20;
            var plotW = w - padL - padR; var plotH = h - padT - padB;
            var minP = 1e9; var maxP = -1e9;
            for (var i2=0;i2<visible.length;i2++) { var cd2=visible[i2]; if(cd2.l<minP)minP=cd2.l; if(cd2.h>maxP)maxP=cd2.h; }
            if (fc && fc.length>0) { for (var f2=0;f2<fc.length;f2++){ var fv=fc[f2].v; if(fv<minP)minP=fv; if(fv>maxP)maxP=fv; }}
            var range = maxP-minP; if(range<=0) range=1;
            var candleSpace = plotW / visible.length;
            ctx.lineWidth = 1;
            ctx.font = '10px monospace';
            ctx.fillStyle = Theme.textDim;
            ctx.strokeStyle = Theme.accentAlt;
            ctx.globalAlpha = 0.8;
            ctx.beginPath(); ctx.rect(padL, padT, plotW, plotH); ctx.stroke();
            ctx.globalAlpha = 1;

            // Candles
            for (var cIdx=0; cIdx<visible.length; cIdx++) {
                var cd = visible[cIdx];
                var xCenter = padL + candleSpace * (cIdx + 0.5);
                var pxHigh = padT + (1 - (cd.h - minP)/range) * plotH;
                var pxLow  = padT + (1 - (cd.l - minP)/range) * plotH;
                var pxOpen = padT + (1 - (cd.o - minP)/range) * plotH;
                var pxClose= padT + (1 - (cd.c - minP)/range) * plotH;
                var bull = cd.c >= cd.o;
                var bodyTop = bull ? pxClose : pxOpen;
                var bodyBottom = bull ? pxOpen : pxClose;
                var bodyH = Math.max(2, bodyBottom - bodyTop);
                var bodyW = Math.max(3, candleSpace*0.55);
                ctx.strokeStyle = wickColor;
                ctx.beginPath(); ctx.moveTo(xCenter, pxHigh); ctx.lineTo(xCenter, pxLow); ctx.stroke();
                ctx.fillStyle = bull ? bullColor : bearColor;
                ctx.globalAlpha = 0.9; ctx.fillRect(xCenter - bodyW/2, bodyTop, bodyW, bodyH);
            }

            // Forecast line
            if (fc && fc.length>0) {
                ctx.save(); ctx.setLineDash([4,4]);
                // Farbverlauf für Forecast: Start = Accent, Ende = AccentAlt halb transparent
                var gradLine = ctx.createLinearGradient(padL, padT, padL+plotW, padT);
                gradLine.addColorStop(0, Theme.accent);
                gradLine.addColorStop(1, Theme.accentAlt);
                ctx.strokeStyle = gradLine;
                ctx.globalAlpha = forecastOpacity;
                ctx.lineWidth = 1.4; ctx.beginPath();
                var startX = padL + candleSpace*(visible.length - 1 + 0.5);
                var lastCandle = visible[visible.length-1];
                for (var k=0;k<fc.length;k++) {
                    var fx = startX + candleSpace*(k+1);
                    var fy = padT + (1 - (fc[k].v - minP)/range) * plotH;
                    if(k===0) ctx.moveTo(startX, padT + (1 - (lastCandle.c - minP)/range) * plotH);
                    ctx.lineTo(fx, fy);
                }
                ctx.stroke(); ctx.restore();
            }
        }
        Connections { target: chartDataModel; function onChanged(){ canvas.requestPaint(); } }
        Connections { target: predictionsModel; function onChanged(){ canvas.requestPaint(); } }
        Timer { interval: 4000; running: root.useMock; repeat: true; onTriggered: { root.ensureMock(); canvas.requestPaint(); } }
        Component.onCompleted: requestAnimationFrame(function(){ canvas.requestPaint(); })
    }

    // Header Overlay mit erweiterten Infos
    Row {
        spacing: 12
        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 6
        Rectangle { radius: 4; border.width: 1
            property real _cp: root.changePct()===undefined?0:root.changePct()
            property real _fp: root.forecastDiffPct()===undefined?0:root.forecastDiffPct()
            property bool conflict: (_cp>0 && _fp<0) || (_cp<0 && _fp>0)
            property color baseColor: conflict ? Theme.warning : (_cp>0 ? Theme.success : (_cp<0 ? Theme.danger : Theme.accentAlt))
            // Intensität skalieren (max 8%)
            property real intensity: Math.min(1.0, Math.abs(_cp)/8.0)
            border.color: conflict ? Theme.warning : Theme.accentAlt
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, conflict ? 0.28 : 0.18*parent.intensity) }
                GradientStop { position: 1.0; color: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, conflict ? 0.10 : 0.04) }
            }
            Behavior on baseColor { ColorAnimation { duration: 380 } }
            Behavior on intensity { NumberAnimation { duration: 340; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 300 } }
            // Puls bei Konflikt (leichter Overlay Effekt)
            Rectangle { anchors.fill: parent; radius: parent.radius; visible: parent.conflict; color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
                SequentialAnimation on opacity { running: parent.conflict; loops: Animation.Infinite
                    NumberAnimation { from: 0.15; to: 0.45; duration: 900; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.45; to: 0.15; duration: 900; easing.type: Easing.InOutQuad }
                }
            }
            Row { anchors.margins: 6; anchors.fill: parent; spacing: 10
                // Symbol
                Text { text: root.currentTicker; color: Theme.accent; font.pixelSize: 14; font.bold: true }
                // Letzter Preis
                Text { id: lastPriceLabel; color: Theme.text; font.pixelSize: 14; text: (function(){ var v=root.lastClose(); return v===undefined?"--":Number(v).toFixed(2); })() }
                // Change abs & % (berechnet clientseitig, nur bei >=2 Kerzen)
                Text { id: changeLabel; font.pixelSize: 13;
                    color: (function(){ var d=root.changeAbs(); if (d===undefined) return Theme.textDim; return d>0?Theme.success:(d<0?Theme.danger:Theme.textDim); })();
                    text: (function(){ var d=root.changeAbs(); var p=root.prevClose(); if (d===undefined||p===undefined) return "-- (--)"; var pct=root.changePct(); return (d>0?"+":"")+d.toFixed(2)+" ("+(pct>0?"+":"")+pct.toFixed(2)+"%)"; })() }
                // Movement Badge > +2% oder < -2%
                Rectangle { id: moveBadge;
                    visible: (function(){ var pct=root.changePct(); return pct!==undefined && Math.abs(pct)>=2; })();
                    radius: 3; color: (function(){ var pct=root.changePct(); if (pct===undefined) return Theme.accentAlt; return pct>0?Theme.success:(pct<0?Theme.danger:Theme.accentAlt); })();
                    border.color: '#222'; border.width: 1; height: 18; width: badgeText.implicitWidth + 10; anchors.verticalCenter: changeLabel.verticalCenter;
                    Row { anchors.fill: parent; anchors.margins: 4
                        Text { id: badgeText; font.pixelSize: 11; font.bold: true; color: Theme.bg; text: (function(){ var pct=root.changePct(); if(pct===undefined) return ""; return (pct>0?"+":"")+pct.toFixed(1)+"%"; })() }
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                // Forecast Diff (letzter Forecast-Punkt vs letzter Close)
                Text { id: forecastDiffLabel; font.pixelSize: 13;
                    color: (function(){ var d=root.forecastDiffAbs(); if (d===undefined) return Theme.textDim; return d>0?Theme.success:(d<0?Theme.danger:Theme.textDim); })();
                    text: (function(){ var d=root.forecastDiffAbs(); var pct=root.forecastDiffPct(); if (d===undefined||pct===undefined) return "-- (--)"; return (d>0?"+":"")+d.toFixed(2)+" ("+(pct>0?"+":"")+pct.toFixed(2)+"%)"; })() }
                Rectangle { id: forecastBadge;
                    visible: (function(){ var pct=root.forecastDiffPct(); return pct!==undefined && Math.abs(pct)>=2.5; })();
                    radius: 3; color: (function(){ var pct=root.forecastDiffPct(); if (pct===undefined) return Theme.accentAlt; return pct>0?Theme.success:(pct<0?Theme.danger:Theme.accentAlt); })();
                    border.color: '#222'; border.width: 1; height: 18; width: forecastBadgeText.implicitWidth + 10; anchors.verticalCenter: forecastDiffLabel.verticalCenter;
                    Row { anchors.fill: parent; anchors.margins: 4
                        Text { id: forecastBadgeText; font.pixelSize: 11; font.bold: true; color: Theme.bg; text: (function(){ var pct=root.forecastDiffPct(); if(pct===undefined) return ""; return (pct>0?"+":"")+pct.toFixed(1)+"%"; })() }
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                // Letzter Poll (UTC) Kurzform
                Text {
                    id: pollTimeLabel
                    font.pixelSize: 11
                    color: Theme.textDim
                    text: poller && poller.lastPollTime ? poller.lastPollTime.slice(11,19) + "Z" : "--"
                    ToolTip.visible: maPollInfo.containsMouse
                    ToolTip.text: poller && poller.lastPollTime ? poller.lastPollTime : "Keine Poll Zeit"
                    MouseArea { id: maPollInfo; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
