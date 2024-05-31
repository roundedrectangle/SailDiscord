import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property string title
    property string icon

    Image {
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
