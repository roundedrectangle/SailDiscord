import QtQuick 2.5
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
// This file has logic for general attachment displaying functionality for all supported types.

Item {
    id: root
    property var model
    property bool fullscreen: false
    anchors.fill: parent

    signal toggleControls

    Loader {
        anchors.fill: parent
        sourceComponent:
            switch (model.type) {
            case 1: return unknownPreview
            case 2: return fullscreen ? imageFullscreenPreview : imagePreview
            }
    }

    Component {
        id: imagePreview
        Item {
            Image {
                id: img
                source: model.url
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: !model.spoiler || fullscreen
            }

            FastBlur {
                visible: !img.visible
                anchors.fill: img
                source: img
                radius: 100

                Label {
                    text: qsTr("SPOILER")
                    anchors.centerIn: parent
                    font.bold: true
                    color: Theme.highlightColor
                }
            }
        }
    }

    Component {
        id: imageFullscreenPreview
        ZoomableImage {
            source: model.url
            onToggleControls: root.toggleControls()
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
