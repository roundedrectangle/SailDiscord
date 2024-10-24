import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property var _model

    color: Theme.secondaryHighlightColor
    wrapMode: Text.Wrap
    width: parent.width

    text: switch(_model.type) {
        case 'join':
        case 'newmember': // FIXME: message reference and main messages unified code
            return _genText(qsTr("%1 joined the server"), _model._author)
        case 'unknown':
        case 'unknownmessage':
            return _genText(qsTr("Unknown message type: %1"), _model.APIType)
        default: console.log("not found for "+_model.type)
    }
    function _genText(escaped, highlighted) { return escaped.arg(Theme.highlightText(highlighted, highlighted, Theme.highlightColor)) }
}
