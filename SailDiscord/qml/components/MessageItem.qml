import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client
    property bool sameAuthorAsBefore

    width: parent.width
    contentHeight: row.height

    Row {
        id: row
        //width: parent.width
        width: (appSettings.sentBehaviour != "n") ? Math.min(parent.width-((appSettings.messagesLessWidth && sent && appSettings.sentBehaviour != "n") ? Theme.paddingLarge : 0), profileIcon.width+iconPadding.width+leftPadding.width+Math.max(contentsLbl.implicitWidth, authorLbl.width)) : parent.width-((appSettings.messagesLessWidth && sent) ? Theme.paddingLarge : 0)
        height: childrenRect.height
        anchors.right: (sent && appSettings.sentBehaviour != "n") ? parent.right : undefined
        layoutDirection: (sent && appSettings.sentBehaviour == "r") ? Qt.RightToLeft : Qt.LeftToRight

        Item { id: leftPadding; height: 1; width: switch (appSettings.messagesPadding) {
           default: case "n": return 0
           case "s": return sent ? Theme.paddingLarge : 0
           case "r": return sent ? 0 : Theme.paddingLarge
           case "a": return Theme.paddingLarge
        } }

        Image {
            id: profileIcon
            source: pfp
            height: switch (appSettings.messageSize) {
                    default: case "l": Theme.iconSizeLarge; break
                    case "L": Theme.iconSizeExtraLarge; break
                    case "m": Theme.iconSizeMedium; break
                    case "a": Theme.iconSizeLauncher; break
                    case "s": Theme.iconSizeSmall; break
                    case "t": Theme.iconSizeSmallPlus; break
                    case "S": Theme.iconSizeExtraSmall; break
                }
            width: height
            visible: !sameAuthorAsBefore && !appSettings.oneAuthor

            property bool rounded: true
            property bool adapt: true

            layer.enabled: rounded
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: profileIcon.width
                    height: profileIcon.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: profileIcon.adapt ? profileIcon.width : Math.min(profileIcon.width, profileIcon.height)
                        height: profileIcon.adapt ? profileIcon.height : width
                        radius: Math.min(width, height)
                    }
                }
            }
        }

        Item { id: iconPadding; height: 1; width: Theme.paddingLarge;
            visible: !(sameAuthorAsBefore && !appSettings.oneAuthor) || appSettings.oneAuthorPadding; }

        Column {
            id: textContainer
            width: (appSettings.sentBehaviour == "a") ? Math.min(parent.width-(profileIcon.width+iconPadding.width+leftPadding.width), Math.max(contentsLbl.paintedWidth, authorLbl.width)) : parent.width-(profileIcon.width+iconPadding.width+leftPadding.width)
            Label {
                id: authorLbl
                text: author
                color: Theme.secondaryColor
                visible: !sameAuthorAsBefore && !appSettings.oneAuthor
            }

            Label {
                id: contentsLbl
                text: contents
                wrapMode: Text.Wrap
                width: Math.min(parent.width, implicitWidth)
                anchors.right: (sent && appSettings.sentBehaviour != "n" && appSettings.alignMessagesText) ? parent.right : undefined
            }

            Item { height: Theme.paddingLarge; width: 1; }
        }
    }
}
