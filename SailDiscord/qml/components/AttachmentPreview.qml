import QtQuick 2.0
import Sailfish.Silica 1.0

SlideshowView {
    property var attachments
    //property int maxHeight: -1

    width: parent.width
    height: {
        if (attachments.count > 0) {
            if (attachments.get(0).maxheight > -1) {
                //console.log(maxHeight, Theme.dp(500))
                //console.log(Math.min(maxHeight, Theme.dp(500)), attachments.get(0).url)
                return Math.min(attachments.get(0).maxheight, Theme.dp(500))
            } else return Theme.itemSizeLarge
        } else return 0
    }
    //height: attachments.count < 1 ? 0 : (maxHeight < 0 ? Theme.itemSizeLarge : (Math.min(maxHeight, Theme.dp(500))))
    model: attachments

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

                /*onStatusChanged: if (status == Image.Ready){
                    maxHeight = Math.max(sourceSize.height, maxHeight)
                                     console.log(maxHeight, url)
                                 }*/
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
