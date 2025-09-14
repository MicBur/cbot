pragma Singleton
import QtQuick 2.15

QtObject {
    // Main colors
    readonly property color bg: "#0a0a0a"
    readonly property color bgElevated: "#111418"
    readonly property color bgHighlight: "#1a1f24"
    readonly property color accent: "#00ffff"
    readonly property color accentAlt: "#00e0ff"
    readonly property color accentDim: "#007a8a"
    readonly property color text: "#e6f6f7"
    readonly property color textDim: "#7aa5a9"
    readonly property color textMuted: "#4a6266"
    
    // Status colors
    readonly property color danger: "#ff3b3b"
    readonly property color dangerDim: "#cc2e2e"
    readonly property color success: "#2ecc71"
    readonly property color successDim: "#27ae60"
    readonly property color warning: "#ffb347"
    readonly property color warningDim: "#f39c12"
    readonly property color info: "#3498db"
    
    // UI properties
    readonly property int radius: 8
    readonly property int radiusSmall: 4
    readonly property int radiusLarge: 12
    
    // Animation durations
    readonly property int durFast: 120
    readonly property int durMed: 260
    readonly property int durSlow: 400
    
    // Shadows
    readonly property string shadowLight: "#20000000"
    readonly property string shadowMedium: "#40000000"
    readonly property string shadowDark: "#80000000"
}
