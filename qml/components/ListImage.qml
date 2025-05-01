import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Asset {
    // A rounded image.
    id: asset

    property bool forceVisibility // force to be visible and full size even when no icon is available
    property string errorString
    property bool extendedRadius
    property bool disableAnimations
    property real defaultSize: Theme.iconSizeLarge

    height: defaultSize
    width: visible ? height : 0
    visible: source != "" || forceVisibility

    signal clicked

    // Credit for initial implementation to: https://stackoverflow.com/a/32710773
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: asset.width
            height: asset.height
            radius: Math.min(width, height) / (extendedRadius ? 4 : 1)
            Behavior on radius {
                NumberAnimation { duration: 150 }
                enabled: !disableAnimations && shared.active
            }
        }
    }

    BusyIndicator {
        z: 2
        anchors.centerIn: parent
        size: BusyIndicatorSize.Medium
        running: asset.imageStatus === Image.Loading
    }

    IconButton {
        // we can't use SilicaMouseArea, so why not use other hacky ways to get into harbour ?:) hehe
        id: iconButtonHelper
        anchors.fill: parent
        z: 1
        enabled: asset.visible
        onClicked: asset.clicked()
        icon.anchors.fill: iconButtonHelper
        Rectangle {
            anchors.fill: parent
            parent: iconButtonHelper.icon
            color: Theme.highlightColor
            opacity: Theme.opacityLow
            visible: parent.highlighted
        }
    }
}
