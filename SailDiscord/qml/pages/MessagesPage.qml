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
            sameAuthorAsBefore: (msgModel.get(index-1) == undefined) ? false : msgModel.get(index-1)._author == _author
        }
    }

    ListModel {
        id: msgModel

        Component.onCompleted: {
            python.setHandler("message", function (_serverid, _channelid, _id, _author, _contents, _icon, _sent) {
                if ((_serverid != guildid) || (_channelid != channelid)) return;
                append({messageId: _id, _author: _author, _contents: _contents, _pfp: _icon, _sent: _sent})
                messagesList.forceLayout()
            })
        }
    }

    Component.onCompleted: {
        python.setCurrentChannel(guildid, channelid)
    }

    Component.onDestruction: {
        python.resetCurrentChannel()
    }
}
