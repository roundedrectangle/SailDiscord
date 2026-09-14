import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property bool down
    property bool highlight: true
    signal clicked

    property real size: 1
    width: parent.itemWidth * size
    implicitHeight: Theme.itemSizeSmall

    property bool _calculateWidth: true
    onVisibleChanged:
        if (parent && parent.itemWidthChanged && _calculateWidth)
            parent.itemWidthChanged()
}
