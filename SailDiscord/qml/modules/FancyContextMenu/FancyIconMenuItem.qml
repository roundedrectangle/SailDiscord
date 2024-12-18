import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    property bool down
    property bool highlighted
    property bool _invertColors
    signal clicked

    width: parent.itemWidth
    height: Theme.itemSizeSmall

    property alias icon: icon
    property alias text: label.text
    property alias _menuItem: label

    Row {
        width: icon.width + label.width
        spacing: Theme.paddingMedium
        anchors.centerIn: parent
        Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
        }
        FancyMenuItem {
            id: label
            width: Math.min(implicitWidth, root.width - icon.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
