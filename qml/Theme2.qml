pragma Singleton
import QtQuick 2.15

/**
 * Enhanced Theme System with comprehensive design tokens
 */
QtObject {
    // Color Palette - Dark Theme
    readonly property color primary: "#1E88E5"
    readonly property color primaryLight: "#4FC3F7"
    readonly property color primaryDark: "#1565C0"
    
    readonly property color secondary: "#FFC107"
    readonly property color secondaryLight: "#FFD54F"
    readonly property color secondaryDark: "#F57C00"
    
    readonly property color background: "#0A0E1A"
    readonly property color surface: "#141923"
    readonly property color surfaceElevated: "#1C2331"
    readonly property color surfaceOverlay: "#252C3E"
    
    // Semantic Colors
    readonly property color success: "#4CAF50"
    readonly property color successLight: "#81C784"
    readonly property color successDark: "#388E3C"
    
    readonly property color danger: "#F44336"
    readonly property color dangerLight: "#EF5350"
    readonly property color dangerDark: "#C62828"
    
    readonly property color warning: "#FF9800"
    readonly property color warningLight: "#FFB74D"
    readonly property color warningDark: "#F57C00"
    
    readonly property color info: "#2196F3"
    readonly property color infoLight: "#64B5F6"
    readonly property color infoDark: "#1976D2"
    
    // Text Colors
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#B0BEC5"
    readonly property color textDisabled: "#616161"
    readonly property color textHint: "#757575"
    
    // Chart Colors
    readonly property var chartColors: [
        "#1E88E5", "#43A047", "#FB8C00", "#E53935", "#8E24AA",
        "#00ACC1", "#FFB300", "#546E7A", "#D81B60", "#6D4C41"
    ]
    
    // Gradients
    readonly property Gradient primaryGradient: Gradient {
        GradientStop { position: 0.0; color: primaryLight }
        GradientStop { position: 1.0; color: primaryDark }
    }
    
    readonly property Gradient successGradient: Gradient {
        GradientStop { position: 0.0; color: successLight }
        GradientStop { position: 1.0; color: successDark }
    }
    
    readonly property Gradient dangerGradient: Gradient {
        GradientStop { position: 0.0; color: dangerLight }
        GradientStop { position: 1.0; color: dangerDark }
    }
    
    // Typography
    readonly property font h1: Qt.font({
        family: "Roboto",
        pixelSize: 32,
        weight: Font.Bold,
        letterSpacing: -0.5
    })
    
    readonly property font h2: Qt.font({
        family: "Roboto",
        pixelSize: 24,
        weight: Font.Bold,
        letterSpacing: -0.3
    })
    
    readonly property font h3: Qt.font({
        family: "Roboto",
        pixelSize: 20,
        weight: Font.Medium,
        letterSpacing: 0
    })
    
    readonly property font h4: Qt.font({
        family: "Roboto",
        pixelSize: 18,
        weight: Font.Medium,
        letterSpacing: 0.1
    })
    
    readonly property font body1: Qt.font({
        family: "Roboto",
        pixelSize: 16,
        weight: Font.Normal,
        letterSpacing: 0.15
    })
    
    readonly property font body2: Qt.font({
        family: "Roboto",
        pixelSize: 14,
        weight: Font.Normal,
        letterSpacing: 0.1
    })
    
    readonly property font caption: Qt.font({
        family: "Roboto",
        pixelSize: 12,
        weight: Font.Normal,
        letterSpacing: 0.4
    })
    
    readonly property font button: Qt.font({
        family: "Roboto",
        pixelSize: 14,
        weight: Font.Medium,
        letterSpacing: 0.75,
        capitalization: Font.AllUppercase
    })
    
    readonly property font mono: Qt.font({
        family: "Roboto Mono",
        pixelSize: 14,
        weight: Font.Normal
    })
    
    // Spacing System (4px base)
    readonly property int spacing1: 4
    readonly property int spacing2: 8
    readonly property int spacing3: 12
    readonly property int spacing4: 16
    readonly property int spacing5: 20
    readonly property int spacing6: 24
    readonly property int spacing8: 32
    readonly property int spacing10: 40
    readonly property int spacing12: 48
    readonly property int spacing16: 64
    
    // Border Radius
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusXLarge: 16
    readonly property int radiusRound: 999
    
    // Elevation (Shadows)
    readonly property var elevation1: DropShadow {
        color: "#40000000"
        radius: 4
        samples: 9
        horizontalOffset: 0
        verticalOffset: 1
    }
    
    readonly property var elevation2: DropShadow {
        color: "#50000000"
        radius: 8
        samples: 17
        horizontalOffset: 0
        verticalOffset: 2
    }
    
    readonly property var elevation3: DropShadow {
        color: "#60000000"
        radius: 12
        samples: 25
        horizontalOffset: 0
        verticalOffset: 4
    }
    
    readonly property var elevation4: DropShadow {
        color: "#70000000"
        radius: 16
        samples: 33
        horizontalOffset: 0
        verticalOffset: 6
    }
    
    // Animation Durations
    readonly property int durationInstant: 0
    readonly property int durationFast: 150
    readonly property int durationNormal: 300
    readonly property int durationSlow: 500
    readonly property int durationVerySlow: 1000
    
    // Easing Curves
    readonly property var easingStandard: Easing.OutCubic
    readonly property var easingDecelerate: Easing.OutQuint
    readonly property var easingAccelerate: Easing.InCubic
    readonly property var easingSharp: Easing.InOutCubic
    readonly property var easingOvershoot: Easing.OutBack
    
    // Component Heights
    readonly property int buttonHeight: 36
    readonly property int buttonHeightLarge: 48
    readonly property int inputHeight: 40
    readonly property int toolbarHeight: 56
    readonly property int listItemHeight: 48
    readonly property int listItemHeightLarge: 72
    
    // Opacity Values
    readonly property real opacityDisabled: 0.38
    readonly property real opacityMedium: 0.60
    readonly property real opacityHigh: 0.87
    readonly property real opacityFull: 1.0
    
    // Icon Sizes
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeMedium: 24
    readonly property int iconSizeLarge: 32
    readonly property int iconSizeXLarge: 48
    
    // Z-Index Layers
    readonly property int zBackground: 0
    readonly property int zContent: 1
    readonly property int zElevated: 10
    readonly property int zModal: 100
    readonly property int zTooltip: 200
    readonly property int zNotification: 300
    readonly property int zDebug: 999
    
    // Utility Functions
    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity)
    }
    
    function mix(color1, color2, ratio) {
        return Qt.rgba(
            color1.r * (1 - ratio) + color2.r * ratio,
            color1.g * (1 - ratio) + color2.g * ratio,
            color1.b * (1 - ratio) + color2.b * ratio,
            color1.a * (1 - ratio) + color2.a * ratio
        )
    }
    
    function isDark(color) {
        var luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
        return luminance < 0.5
    }
    
    function contrastColor(background) {
        return isDark(background) ? textPrimary : "#000000"
    }
}