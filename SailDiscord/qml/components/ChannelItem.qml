import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    width: parent.width
    contentHeight: row.height

    Row {
        id: row
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        spacing: Theme.paddingLarge
        height: Theme.itemSizeSmall

        Icon {
            id: channelIcon
            anchors.verticalCenter: parent.verticalCenter
            source: switch (icon) {
                case "voice":
                case "stage_voice":
                    "image://theme/icon-m-browser-sound"
                    break
                case "news":
                    "image://theme/icon-m-send"
                    break
                case "private":
                    "image://theme/icon-m-device-lock"
                    break
                case "text":
                    "image://theme/icon-m-edit"
                    break
                case "forum":
                case "directory":
                    "image://theme/icon-m-folder"
                    break
                default:
                    "image://theme/icon-m-warning"
                    break
            }
            opacity: hasPermissions ? 1 : Theme.opacityLow
            highlighted: unread || parent.parent.highlighted
        }

        Label {
            text: name
            width: parent.width - channelIcon.width - channelUnreadCount.width - parent.spacing*(channelUnreadCount.visible ? 2 : 1)
            truncationMode: TruncationMode.Fade
            anchors.verticalCenter: parent.verticalCenter
            textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
            highlighted: unread || parent.parent.highlighted
            opacity: hasPermissions ? 1 : Theme.opacityLow
        }

        Rectangle {
            id: channelUnreadCount
            visible: mentions > 0
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? children[0].width + Theme.paddingSmall*2 : 0
            height: children[0].height + Theme.paddingSmall*2
            radius: height/2
            color: Theme.highlightColor
            Label {
                text: mentions > 100000 ? '100k+' : mentions
                color: Theme.primaryColor
                anchors.centerIn: parent
            }
        }
    }

    onClicked: openChannel(model)

    menu: Component { ContextMenu {
            hasContent: appSettings.developerMode
            MenuItem {
                text: qsTranslate("General", "Copy channel ID")
                visible: appSettings.developerMode
                onClicked: Clipboard.text = channelid
            }
        } }
}
