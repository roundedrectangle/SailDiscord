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

        delegate: MessageItem {
            contents: contents
            author: author
        }
    }

    ListModel {
        id: model

        Component.onCompleted: {
            append({_id: 0, _author: "me", _contents: "hello world"})
            append({_id: 0, _author: "me", _contents: "hello world"})
            append({_id: 0, _author: "me", _contents: "hello world"})

            python.setHandler("message", function (_serverid, _channelid, _id, _author, _contents) {
                if ((_serverid != guildid) || (_channelid != channelid)) return;
                append({messageId: _id, author: _author, contents: _contents})
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
