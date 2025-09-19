pragma Singleton
import QtQuick 2.15

QtObject {
    // Dark theme with modern gradients and neon accents
    readonly property color bg: "#050507"
    readonly property color bgElevated: "#0a0a0f"
    readonly property color bgCard: "#111119"
    readonly property color bgGlass: "#ffffff08"
    
    // Neon cyan accent colors
    readonly property color accent: "#00ffff"
    readonly property color accentAlt: "#00e0ff"
    readonly property color accentDark: "#00a8cc"
    readonly property color accentGlow: "#00ffff"
    
    // Text colors
    readonly property color text: "#f0f6fc"
    readonly property color textDim: "#8b949e"
    readonly property color textMuted: "#484f58"
    
    // Status colors with glow
    readonly property color danger: "#ff4757"
    readonly property color dangerGlow: "#ff4757"
    readonly property color success: "#00ff88"
    readonly property color successGlow: "#00ff88"
    readonly property color warning: "#ffd93d"
    readonly property color warningGlow: "#ffd93d"
    
    // Chart colors
    readonly property color chartGrid: "#1a1a2e"
    readonly property color chartLine: "#00ffff"
    readonly property color chartFill: "#00ffff20"
    
    // Gradients
    readonly property var bgGradient: ["#050507", "#0a0a0f"]
    readonly property var accentGradient: ["#00ffff", "#00e0ff", "#00a8cc"]
    readonly property var glowGradient: ["#00ffff40", "#00ffff00"]
    
    // Border and effects
    readonly property color border: "#ffffff10"
    readonly property color borderHover: "#ffffff20"
    readonly property real glowRadius: 20
    readonly property real shadowRadius: 16
    
    // Layout
    readonly property int radius: 12
    readonly property int radiusSmall: 6
    readonly property int radiusLarge: 16
    
    // Animation durations
    readonly property int durFast: 150
    readonly property int durMed: 300
    readonly property int durSlow: 600
    readonly property int durGlow: 1200
}
