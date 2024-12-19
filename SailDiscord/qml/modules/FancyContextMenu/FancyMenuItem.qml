import QtQuick 2.0
import Sailfish.Silica 1.0
import "private"

FadeableXMenuItem {
    width: parent.itemWidth
    property bool _calculateWidth: true
    onVisibleChanged: if (parent.calculateItemWidth && _calculateWidth) parent.calculateItemWidth()
}
