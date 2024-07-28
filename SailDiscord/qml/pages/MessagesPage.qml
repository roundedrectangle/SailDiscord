import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

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
    }

    ListModel {
        id: model
    }

    Component.onCompleted: {
        // TODO: send that the channel is opened to python
    }

    Component.onDestroyed: {
        // TODO: send that the channel is closed to python
    }
}
