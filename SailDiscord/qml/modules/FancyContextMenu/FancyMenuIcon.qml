import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property bool down
    signal clicked
    property alias icon: icon

    width: parent.itemWidth
    height: Theme.itemSizeSmall//icon.height
    Icon {
        id: icon
        anchors.centerIn: parent
    }

    onVisibleChanged: parent.calculateItemWidth()
}
