import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    property var _model
    property color highlightColor: Theme.highlightColor
    property alias label: _label

    width: parent.width
    contentHeight: _label.height

    Label {
        id: _label
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
        function _genText(escaped, highlighted) { return escaped.arg(Theme.highlightText(highlighted, highlighted, highlightColor)) }
    }

    onClicked: switch (_model.type) {
                   case 'join':
                   case 'newmember':
                       pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"), { userid: _model.userid, name: _model._author, icon: _model._pfp })
                       break
               }
}
