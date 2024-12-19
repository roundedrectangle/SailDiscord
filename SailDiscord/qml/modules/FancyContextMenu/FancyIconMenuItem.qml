import QtQuick 2.0
import Sailfish.Silica 1.0
import "private"

Item {
    id: root
    property bool down
    property bool highlighted
    property bool _invertColors
    signal clicked

    width: parent.itemWidth
    height: Theme.itemSizeSmall

    property bool _calculateWidth: true
    onVisibleChanged: if (parent.calculateItemWidth && _calculateWidth) parent.calculateItemWidth()

    property alias icon: icon
    property alias text: label.text
    property alias direction: row.layoutDirection

    property alias _menuItem: label
    property alias _content: row

    Row {
        id: row
        width: icon.width + label.width
        spacing: (icon.visible && label.visible) ? Theme.paddingMedium : 0
        anchors.centerIn: parent
        Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            visible: !!source
        }
        FadeableXMenuItem {
            id: label
            width: Math.min(implicitWidth, root.width - icon.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            visible: !!text
        }
    }
}
