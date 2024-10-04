import QtQuick 2.0
import Sailfish.Silica 1.0

SlideshowView {
    width: parent.width
    height: {
        if (attachments.count > 0) {
            JSON.stringify(attachments.get(0)) // Wait until object is initialized FIXME: find a better way
            if (attachments.get(0).maxheight > -1)
                if (Math.abs(attachments.get(0).maxwidth - attachments.get(0).maxheight) < Theme.dp(50))
                    return Theme.dp(500)
                else return Math.max(Math.min(attachments.get(0).maxheight, Theme.dp(500)), Theme.dp(200))
            else return Theme.itemSizeLarge
        } return 0
    }

    delegate: MouseArea {
        property var itemModel: model
        width: parent.width
        height: parent.height
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/FullscreenAttachmentPage.qml"), {model: attachments, index: index})

        GeneralAttachmentView { model: parent.itemModel }
    }
}
