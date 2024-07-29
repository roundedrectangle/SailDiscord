import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author

    Column {
        Label {
            text: author
            color: Theme.secondaryColor
        }

        Label {
            text: contents
        }
    }
}
