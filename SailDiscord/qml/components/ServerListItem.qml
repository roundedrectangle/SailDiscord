import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    id: root
    property string title
    property string icon

    property bool hasIcon: icon != "None" && icon != ""

    property bool _iconAvailable: hasIcon || appSettings.emptySpace

    contentWidth: parent.width
    contentHeight: _iconAvailable ? Theme.itemSizeLarge : Theme.itemSizeSmall;

    Column {
        width: parent.width - Theme.horizontalPageMargin*2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Row {
            //spacing: _iconAvailable ? Theme.paddingLarge : 0

            ListImage {
                icon: root.icon
                maxHeight: root.height
                forceVisibility: appSettings.emptySpace
            }

            Item { id: iconPadding; height: 1; width: _iconAvailable ? Theme.paddingLarge : 0; }

            Label {
                //width: (parent.width - profileIcon.width - iconPadding.width)
                text: title
                //fontSizeMode: Text.HorizontalFit
                //minimumPixelSize: 1
                //font.pixelSize: 50

                //truncationMode: TruncationMode.Fade
                //horizontalAlignment: Text.AlignLeft

                //anchors.horizontalCenter: parent.horizontalCenter
                //horizontalAlignment: Text.AlignLeft
                //truncationMode: TruncationMode.Fade
            }
        }
    }
}
