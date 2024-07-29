import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author

    width: parent.width
    height: column.height

    Column {
        id: column
        width: parent.width
        height: childrenRect.height

        Label {
            text: author
            color: Theme.secondaryColor
        }

        Label {
            text: contents
            wrapMode: Text.Wrap
            width: parent.width
        }
    }
}
