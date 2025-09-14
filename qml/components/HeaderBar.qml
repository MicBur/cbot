import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Frontend 1.0

Rectangle {
    id: header
    height: 48
    color: Theme.bgElevated
    property alias title: titleLabel.text
    signal closeRequested()

    RowLayout {
        anchors.fill: parent
        spacing: 16
        MyLabel { id: titleLabel; text: "Title"; color: Theme.accent; font.bold: true; font.pixelSize: 20 }
        Rectangle { Layout.fillWidth: true; color: "transparent" }
        StatusBadge { status: poller.connected ? 1 : 0; label: poller.connected ? "Redis" : "No Redis" }
    }
}
