import QtQuick 2.0
import Sailfish.Silica 1.0
// This file has logic for general attachment displaying functionality for all supported types.

Item {
    property var model
    anchors.fill: parent

    Loader {
        anchors.fill: parent
        sourceComponent:
            switch (model.type) {
            case 1: return unknownPreview
            case 2: return imagePreview
            }
    }

    Component {
        id: imagePreview
        Image {
            source: model.url
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
        }
    }

    Component {
        id: unknownPreview
        Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.centerIn: parent
            color: Theme.secondaryHighlightColor
            text: qsTr("Attachment unsupported: %1").arg('<font color="'+Theme.highlightColor+'">'+model.realtype+'</font>')
        }
    }
}
