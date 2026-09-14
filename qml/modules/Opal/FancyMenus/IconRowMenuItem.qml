import QtQuick 2.0
import Sailfish.Silica 1.0

BaseRowMenuItem {
    property alias icon: icon
    Icon {
        id: icon
        opacity: parent.enabled ? 1.0 : Theme.opacityLow
        anchors.centerIn: parent
    }
}
