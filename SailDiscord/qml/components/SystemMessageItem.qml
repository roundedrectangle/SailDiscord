import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    textFormat: "RichText"
    text: switch(type) {
        case 'join':
            return _genText(qsTr("%1 joined the server"), _author)
        case 'unknown':
            return _genText(qsTr("Unknown message type: %1"), APIType)
    }
    horizontalAlignment: Text.AlignHCenter
    color: Theme.secondaryHighlightColor
    width: parent.width
    wrapMode: Text.Wrap

    function _genText(escaped, highlighted) { return escaped.arg(Theme.highlightText(highlighted, highlighted, Theme.highlightColor)) }
}
