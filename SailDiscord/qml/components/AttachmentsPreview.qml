import QtQuick 2.0
import Sailfish.Silica 1.0

SlideshowView {
    width: parent.width
    height: {
        if (attachments.count > 0) {
            JSON.stringify(attachments.get(0)) // Wait until object is initialized FIXME: find a better way
            if (attachments.get(0).maxheight > -1)
                if (Math.abs(attachments.get(0).maxwidth - attachments.get(0).maxheight) < Theme.dp(50))
                //if (attachments.get(0).maxwidth < Theme.dp(500))
                    return Theme.dp(500)
                else return Math.max(Math.min(attachments.get(0).maxheight, Theme.dp(500)), Theme.dp(200))
            else return Theme.itemSizeLarge
        } return 0
    }

    Component.onCompleted: console.log(height)

    delegate: MouseArea {
        width: parent.width
        height: parent.height
        onClicked: console.log("TODO: load full-screen SlideshowView")

        Loader {
            width: parent.width
            height: parent.height
            sourceComponent:
                switch (type) {
                case 1: return unknownPreview
                case 2: return imagePreview
                }
        }

        Component {
            id: imagePreview
            Image {
                source: url
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
                text: qsTr("Attachment unsupported: %1").arg('<font color="'+Theme.highlightColor+'">'+realtype+'</font>')
            }
        }
    }
}
