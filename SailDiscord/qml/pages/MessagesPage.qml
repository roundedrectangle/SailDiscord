import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string guildid
    property string channelid
    property string name
    property bool isDemo: false

    SilicaListView {
        id: messagesList
        anchors.fill: parent
        model: msgModel

        header: PageHeader {
            id: header
            title: "#"+name
        }

        ViewPlaceholder {
            enabled: msgModel.count === 0
            text: qsTr("No messages")
            hintText: qsTr("Say hi (Coming soon)")
        }

        delegate: MessageItem {
            contents: _contents
            author: _author
            pfp: _pfp
            sent: _sent
            sameAuthorAsBefore: (msgModel.get(index-1) == undefined) ? false : // If this is the first message, false
                                    msgModel.get(index-1)._author == _author
            masterWidth: !sameAuthorAsBefore ? -1 :
                            (msgModel.get(index-1)._masterWidth != -1 ? // If the previous element had masterWidth, use that
                            msgModel.get(index-1)._masterWidth :
                            msgModel.get(index-1)._masterWidth)

            function updateMasterWidth() {
                msgModel.setProperty(index, "_masterWidth", masterWidth == -1 ? innerWidth : masterWidth)
            }

            Component.onCompleted: updateMasterWidth()
            onMasterWidthChanged: updateMasterWidth()
            onInnerWidthChanged: updateMasterWidth()
        }
    }

    ListModel {
        id: msgModel

        Component.onCompleted: {
            if (isDemo) {
                var repeatString = function(string, count) {
                    var result = "";
                    for (var i = 0; i < count; i++) result += string;
                    return result;
                };

                // Append demo messages

                append({messageId: "-1", _author: "you", _contents: "First message!", _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})
                append({messageId: "-1", _author: "you", _contents: "Second message", _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})
                append({messageId: "-1", _author: "you", _contents: "A l "+repeatString("o ", 100)+"ng message.", _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})

                append({messageId: "-1", _author: "notyou", _contents: "First message!", _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})
                append({messageId: "-1", _author: "notyou", _contents: "Second message", _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})
                append({messageId: "-1", _author: "notyou", _contents: "A l "+repeatString("o ", 100)+"ng message.", _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})

                append({messageId: "-1", _author: "you", _contents: repeatString("Hello, world. ", 50), _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})
                append({messageId: "-1", _author: "you", _contents: "Second message", _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})
                append({messageId: "-1", _author: "you", _contents: "A l "+repeatString("o ", 100)+"ng message.", _pfp: "https://cdn.discordapp.com/embed/avatars/0.png", _sent: true, _masterWidth: -1})

                append({messageId: "-1", _author: "notyou", _contents: repeatString("Hello, world. ", 50), _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})
                append({messageId: "-1", _author: "notyou", _contents: "Second message", _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})
                append({messageId: "-1", _author: "notyou", _contents: "A l "+repeatString("o ", 100)+"ng message.", _pfp: "https://cdn.discordapp.com/embed/avatars/1.png", _sent: false, _masterWidth: -1})

                messagesList.forceLayout()
                return
            }
            python.setHandler("message", function (_serverid, _channelid, _id, _author, _contents, _icon, _sent, history) {
                if ((_serverid != guildid) || (_channelid != channelid)) return;
                var data = {messageId: _id, _author: _author, _contents: _contents, _pfp: _icon, _sent: _sent, _masterWidth: -1}
                if (history) insert(0, data); else append(data);
                messagesList.forceLayout()
            })
        }
    }

    Component.onCompleted: {
        if (isDemo) {
            name = "demo-channel"
            guildid = -5
            channelid = -5
            return
        }

        python.setCurrentChannel(guildid, channelid)
    }

    Component.onDestruction: {
        if (isDemo) return
        python.resetCurrentChannel()
    }
}
