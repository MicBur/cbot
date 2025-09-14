pragma Singleton
import QtQuick 2.15
import QtQuick.Window 2.15

QtObject {
    property Window appWindow: null
    
    // Breakpoints
    readonly property int smallScreen: 640
    readonly property int mediumScreen: 1024
    readonly property int largeScreen: 1440
    
    // Current screen size properties
    readonly property bool isSmall: appWindow && appWindow.width <= smallScreen
    readonly property bool isMedium: appWindow && appWindow.width > smallScreen && appWindow.width <= mediumScreen
    readonly property bool isLarge: appWindow && appWindow.width > mediumScreen && appWindow.width <= largeScreen
    readonly property bool isXLarge: appWindow && appWindow.width > largeScreen
    
    // Adaptive sizing functions
    function scaledSize(base) {
        if (!appWindow) return base
        var scale = 1.0
        if (isSmall) scale = 0.8
        else if (isMedium) scale = 0.9
        else if (isXLarge) scale = 1.1
        return Math.round(base * scale)
    }
    
    // Adaptive spacing
    readonly property int spacing: isSmall ? 4 : (isMedium ? 8 : 12)
    readonly property int margin: isSmall ? 8 : (isMedium ? 12 : 16)
    
    // Navigation width
    readonly property int sideNavWidth: isSmall ? 50 : 70
}