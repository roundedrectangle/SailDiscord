import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    id: root
    property string title
    property string icon

    property bool _iconAvailable: (icon != "None" && icon != "") || appSettings.emptySpace

    contentWidth: parent.width
    contentHeight: _iconAvailable ? Theme.itemSizeLarge : Theme.itemSizeSmall

    Row {
        width: parent.width - Theme.horizontalPageMargin*2
        anchors.centerIn: parent
        spacing: _iconAvailable ? Theme.paddingLarge : 0

        ListImage {
            id: profileIcon
            icon: root.icon
            height: root.contentHeight - Theme.paddingSmall*4
            forceVisibility: appSettings.emptySpace
            errorString: title
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - profileIcon.width - parent.spacing*1
            truncationMode: TruncationMode.Fade
            text: title
        }
    }
}
