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
        model: model

        header: PageHeader {
            id: header
            title: "#"+name
        }

        ViewPlaceholder {
            enabled: model.count === 0
            text: qsTr("No messages")
            hintText: qsTr("Say hi (Coming soon)")
        }

        delegate: MessageItem {
            contents: _contents
            author: _author
            pfp: _pfp
            sent: _sent
        }
    }

    ListModel {
        id: model

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
