import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string title
    property string icon

    width: parent.width
    //ListView.view.width
    height: Theme.itemSizeSmall

    //Label {
    //    text: name
    //}

    Column {
        Row {

            Image {
                id: profileIcon
                source: icon
                //height: parent.height
                height: parent.height-4*Theme.paddingSmall
                width: height
            }

            Label {
                //x: Theme.horizontalPageMargin
                //width: parent.width - 2 * x
                //anchors.verticalCenter: parent.verticalCenter
                text: title
                //truncationMode: TruncationMode.Fade
                //font.capitalization: Font.Capitalize
            }
        }

        Separator {
            color: Theme.primaryColor
            horizontalAlignment: Qt.AlignHCenter
        }
    }
}
