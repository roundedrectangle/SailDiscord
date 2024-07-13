import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Column {
    property string title
    property string icon
    Row {

        Image {
            id: profileIcon
            source: icon
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
