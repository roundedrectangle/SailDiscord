import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property string title

    //x: Theme.horizontalPageMargin
    //width: parent.width - 2 * x
    //anchors.verticalCenter: parent.verticalCenter
    text: title
    //truncationMode: TruncationMode.Fade
    //font.capitalization: Font.Capitalize
}
