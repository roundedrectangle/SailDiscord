import QtQuick 2.6
import Sailfish.Silica 1.0

Flow {
    x: Theme.horizontalPageMargin
    width: parent.width - 2*x
    visible: repeater.count > 0
    height: visible ? implicitHeight : 0
    topPadding: Theme.paddingMedium
    spacing: Theme.paddingMedium
    bottomPadding: Theme.paddingMedium

    property string messageId
    property alias model: repeater.model

    Repeater {
        id: repeater

        BackgroundItem {
            id: reactionItem
            contentItem.radius: Theme.paddingSmall
            height: Theme.itemSizeSmall/2
            width: Theme.paddingSmall*3 + emojiAsset.width + countLabel.width
            contentItem.color: _showPress
                               ? highlightedColor
                               : Theme.rgba(me ? palette.highlightBackgroundColor : Theme.overlayBackgroundColor, Theme.opacityFaint)

            Asset {
                id: emojiAsset
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    verticalCenter: parent.verticalCenter
                }
                width: parent.height - Theme.paddingSmall
                height: width
                source: emoji ? shared.getEmojiPath(emoji) : defaultSource
                active: !!emoji || (info && info.source)
                info: asset
            }

            Label {
                id: countLabel
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                    verticalCenter: parent.verticalCenter
                }
                text: count
                highlighted: reactionItem.highlighted || me
            }

            onClicked: toggleReaction(reactionId, !me)
        }
    }
}
