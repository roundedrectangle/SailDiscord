import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Asset {
    //property alias icon: data
    property var icon
    property bool forceVisibility: false // force to be visible and full size even when no icon is available
    property string errorString
    property bool extendedRadius: false
    property bool disableAnimations: false
    property real defaultSize: Theme.iconSizeLarge

    Component.onCompleted: if (icon) console.log(JSON.stringify(info),info = icon)
    onIconChanged: data = info

    id: asset
    height: defaultSize
    width: visible ? height : 0
    visible: source != "" || forceVisibility

    property bool rounded: true
    property bool adapt: true

    signal clicked
    property bool highlightOnClick
    property bool highlighted: false // does not work at all with Asset for now. TODO: remove this at all or make it better somehow

    layer.enabled: rounded
    layer.effect: OpacityMask {
        maskSource: Item {
            width: asset.width
            height: asset.height
            Rectangle {
                anchors.centerIn: parent
                width: asset.adapt ? asset.width : Math.min(asset.width, asset.height)
                height: asset.adapt ? asset.height : width
                radius: extendedRadius ? Math.min(width, height)/4 : Math.min(width, height)
                Behavior on radius {
                    NumberAnimation { duration: 150 }
                    enabled: !disableAnimations && shared.active
                }
            }
        }
    }

    //onStatusChanged: if (status == Image.Error && errorString.length > 0) shared.imageLoadError(errorString)

    ProgressCircle {
        id: progressCircle
        anchors.fill: parent
        visible: asset.item && asset.item.status == Image.Loading

        Timer {
            interval: 32
            repeat: true
            onTriggered: progressCircle.value = (progressCircle.value + 0.01) % 1.0
            running: asset.item && asset.item.status == Image.Loading
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
        enabled: asset.visible

        hoverEnabled: true
        //onPressed: if (highlightOnClick) parent.highlighted = true
        //onEntered: if (highlightOnClick) parent.highlighted = true
        //onReleased: parent.highlighted = false
        //onExited: parent.highlighted = false
    }
}
