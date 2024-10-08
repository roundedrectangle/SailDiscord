import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'
import Sailfish.Share 1.0

FullscreenContentPage {
    property var model
    property int index

    SlideshowView {
        id: slideshow
        anchors.fill: parent
        model: parent.model

        //Component.onCompleted: positionViewAtIndex(index, PathView.Contain) // currentIndex is not available for some reason; this doesn't work too

        delegate: MouseArea {
            property var itemModel: model
            onClicked: overlay.enabled = !overlay.enabled
            width: slideshow.width
            height: slideshow.height
            GeneralAttachmentView { model: itemModel; showSpoiler: false }

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
                        text: itemModel.alt
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
                            onClicked: shared.download(itemModel.url, itemModel.filename)
                        }

                        IconButton {
                            icon.source: "image://theme/icon-m-share"
                            onClicked: shared.shareFile(itemModel.url, itemModel.filename, itemModel.realtype)
                        }
                    }
                }
            }
        }
    }
}
