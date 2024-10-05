import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'

FullscreenContentPage {
    property var model
    property int index

    SlideshowView {
        id: slideshow
        anchors.fill: parent
        model: parent.model

        //Component.onCompleted: positionViewAtIndex(index, PathView.Contain) // currentIndex is not available for some reason

        delegate: MouseArea {
            property var itemModel: model
            onClicked: overlay.enabled = !overlay.enabled
            width: slideshow.width
            height: slideshow.height
            GeneralAttachmentView { model: itemModel }

            Item {
                id: overlay

                enabled: true // toggle this when active/non-active changes
                anchors.fill: parent
                opacity: enabled ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {}}

                IconButton {
                    y: Theme.paddingLarge
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                    }
                    icon.source: "image://theme/icon-m-dismiss"
                    onClicked: pageStack.pop()
                }

                Row {
                    anchors  {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    spacing: Theme.paddingLarge

                    IconButton {
                        icon.source: "image://theme/icon-m-downloads"
                        onClicked: shared.download(itemModel.url, itemModel.filename)
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-share"
                        onClicked: {
                            console.log("TODO: share...")
                        }
                    }
                }
            }
        }
    }
}
