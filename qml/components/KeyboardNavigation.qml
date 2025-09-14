import QtQuick 2.15

Item {
    id: root
    
    // Navigation properties
    property var sideNav: null
    property var notificationDrawer: null
    property var marketList: null
    
    // Keyboard shortcuts
    focus: true
    
    Keys.onPressed: {
        switch(event.key) {
            // Navigation shortcuts
            case Qt.Key_1:
                if (sideNav) sideNav.currentIndex = 0
                event.accepted = true
                break
            case Qt.Key_2:
                if (sideNav) sideNav.currentIndex = 1
                event.accepted = true
                break
            case Qt.Key_3:
                if (sideNav) sideNav.currentIndex = 2
                event.accepted = true
                break
            case Qt.Key_4:
                if (sideNav) sideNav.currentIndex = 3
                event.accepted = true
                break
            case Qt.Key_5:
                if (sideNav) sideNav.currentIndex = 4
                event.accepted = true
                break
                
            // Notification drawer toggle
            case Qt.Key_N:
                if (event.modifiers & Qt.ControlModifier && notificationDrawer) {
                    notificationDrawer.drawerState = notificationDrawer.drawerState === 1 ? 0 : 1
                    event.accepted = true
                }
                break
                
            // Market list navigation
            case Qt.Key_Up:
                if (marketList && marketList.currentIndex > 0) {
                    marketList.currentIndex--
                    event.accepted = true
                }
                break
            case Qt.Key_Down:
                if (marketList && marketList.currentIndex < marketList.count - 1) {
                    marketList.currentIndex++
                    event.accepted = true
                }
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (marketList && marketList.currentItem) {
                    // Trigger selection
                    if (poller && marketList.model.get(marketList.currentIndex)) {
                        poller.currentSymbol = marketList.model.get(marketList.currentIndex).symbol
                    }
                    event.accepted = true
                }
                break
        }
    }
}