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
            contents: _contents
            author: _author
        }
    }

    ListModel {
        id: model

        Component.onCompleted: {
            append({_id: 0, _author: "me", _contents: "hello world"})
            append({_id: 0, _author: "me", _contents: "hello world"})
            append({_id: 0, _author: "me", _contents: "hello world"})
        }
    }

    Component.onCompleted: {
        // TODO: send that the channel is opened to python
    }

    Component.onDestruction: {
        // TODO: send that the channel is closed to python
    }
}
