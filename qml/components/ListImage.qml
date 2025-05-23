import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

HighlightImage {
    property string icon: ''
    property bool forceVisibility: false // force to be visible and full size even when no icon is available
    property string errorString
    property bool extendedRadius: false
    property bool disableAnimations: false
    property real defaultSize: Theme.iconSizeLarge

    id: roundedIcon
    source: (icon != "None" && icon != '') ? icon : ''
    height: defaultSize
    width: visible ? height : 0
    visible: source != "" || forceVisibility

    property bool rounded: true
    property bool adapt: true

    signal clicked
    property bool highlightOnClick
    highlighted: false
    asynchronous: true

    layer.enabled: rounded
    layer.effect: OpacityMask {
        maskSource: Item {
            width: roundedIcon.width
            height: roundedIcon.height
            Rectangle {
                anchors.centerIn: parent
                width: roundedIcon.adapt ? roundedIcon.width : Math.min(roundedIcon.width, roundedIcon.height)
                height: roundedIcon.adapt ? roundedIcon.height : width
                radius: extendedRadius ? Math.min(width, height)/4 : Math.min(width, height)
                Behavior on radius {
                    NumberAnimation { duration: 150 }
                    enabled: !disableAnimations && shared.active
                }
            }
        }
    }

    onStatusChanged: if (status == Image.Error && errorString.length > 0) shared.imageLoadError(errorString)

    ProgressCircle {
        id: progressCircle
        anchors.fill: parent
        visible: parent.status == Image.Loading

        Timer {
            interval: 32
            repeat: true
            onTriggered: progressCircle.value = (progressCircle.value + 0.01) % 1.0
            running: parent.parent.status == Image.Loading
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
        enabled: parent.visible

        hoverEnabled: true
        onPressed: if (highlightOnClick) parent.highlighted = true
        onEntered: if (highlightOnClick) parent.highlighted = true
        onReleased: parent.highlighted = false
        onExited: parent.highlighted = false
    }
}
