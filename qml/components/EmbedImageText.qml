import QtQuick 2.6
import Sailfish.Silica 1.0

Label {
    property alias icon: icon

    width: parent.width
    height: Math.max(implicitHeight, icon.height)
    visible: !!text
    font.pixelSize: Theme.fontSizeSmall
    truncationMode: TruncationMode.Fade


    leftPadding: icon.visible ? (icon.width + Theme.paddingMedium) : 0
    verticalAlignment: Text.AlignVCenter
    Image {
        id: icon
        width: visible ? Theme.iconSizeExtraSmall : 0
        height: width
        anchors.verticalCenter: parent.verticalCenter
        layer.enabled: parent.highlighted
        layer.effect: Component { PressEffect { source: icon } }
    }
}
