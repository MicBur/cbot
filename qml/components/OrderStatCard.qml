import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string title: "Title"
    property int value: 0
    property string icon: "📊"
    property color color: "#2196f3"
    
    height: 80
    color: "#2d2d2d"
    radius: 12
    border.color: root.color
    border.width: 2
    
    // Hover effect
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.color
        opacity: mouseArea.containsMouse ? 0.1 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: root.color
            opacity: 0.2
            
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 18
            }
        }
        
        Column {
            Layout.fillWidth: true
            spacing: 4
            
            Text {
                text: root.value.toString()
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Text {
                text: root.title
                font.pixelSize: 12
                color: "#aaaaaa"
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}