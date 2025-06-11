import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Share 1.0
import '../components'
import "../js/shared.js" as Shared

FullscreenContentPage {
    allowedOrientations: Orientation.All
    property var model
    property int index

    PagedView {
        id: slideshow
        anchors.fill: parent
        model: parent.model
        clip: true

        //Component.onCompleted: positionViewAtIndex(index, PathView.Contain) // currentIndex is not available for some reason; this doesn't work too

        delegate: Item {
            property var itemModel: model
            width: slideshow.width
            height: slideshow.height
            GeneralAttachmentView {
                model: itemModel
                fullscreen: true
                onToggleControls: overlay.enabled = !overlay.enabled
            }
        }
    }

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

        Column {
            anchors  {
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
            }
            width: parent.width

            Label {
                text: model.get(slideshow.currentIndex).alt
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                IconButton {
                    icon.source: "image://theme/icon-m-downloads"
                    onClicked: Shared.download(model.get(slideshow.currentIndex).url, model.get(slideshow.currentIndex).filename)
                }

                IconButton {
                    icon.source: "image://theme/icon-m-share"
                    onClicked: Shared.shareFile(model.get(slideshow.currentIndex).url, model.get(slideshow.currentIndex).filename, model.get(slideshow.currentIndex).realtype)
                }
            }
        }
    }
}
