pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property color bg: "#0a0a0a"
    readonly property color bgElevated: "#111418"
    readonly property color accent: "#00ffff"
    readonly property color accentAlt: "#00e0ff"
    readonly property color text: "#e6f6f7"
    readonly property color textDim: "#7aa5a9"
    readonly property color danger: "#ff3b3b"
    readonly property color success: "#2ecc71"
    readonly property color warning: "#ffb347"

    readonly property int radius: 8
    readonly property int durFast: 120
    readonly property int durMed: 260
}
