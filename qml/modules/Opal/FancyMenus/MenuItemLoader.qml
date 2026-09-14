import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: menuItemLoader
    asynchronous: true

    property int __silica_menuitem

    width: parent.width
    height: active && visible ? Theme.itemSizeSmall : 0

    property bool down
    property bool highlighted
    property bool _invertColors

    signal clicked
    signal earlyClick
    signal delayedClick

    property int xPos

    onXPosChanged:
        if (item && item.hasOwnProperty('xPos'))
            item.xPos = xPos

    onItemChanged:
        if (item) {
            item.down = Qt.binding(function () { return down })
            item.highlighted = Qt.binding(function () { return highlighted })
            item._invertColors = Qt.binding(function () { return _invertColors })
            clicked.connect(item.clicked)
            earlyClick.connect(item.earlyClick)
            delayedClick.connect(item.delayedClick)

            if (item.__opal__fancy_menus__fancy_menu_row) {
                item.menu = menuItemLoader.parent.parent
                item.menuContainer = menuItemLoader.parent
            }
        }
}
