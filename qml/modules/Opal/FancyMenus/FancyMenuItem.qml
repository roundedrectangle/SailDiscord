import QtQuick 2.0
import Sailfish.Silica 1.0

IconTextRowMenuItem {
    property int __silica_menuitem
    width: parent.width

    signal earlyClick
    signal delayedClick

    _useIconOnly: false
    _useShort: false
    text: ''

    onSizeChanged: if (size) console.warn("FancyMenuItem::size is ignored.")
}
