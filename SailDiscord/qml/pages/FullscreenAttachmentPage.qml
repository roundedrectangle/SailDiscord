import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'

FullscreenContentPage {
    id: root
    property var model

    Label {
        text: "Coming soon... "+model.url
        anchors.centerIn: parent
        width: parent.width
        wrapMode: Text.Wrap
    }
}
