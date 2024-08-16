import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client
    property bool sameAuthorAsBefore
    property real masterWidth // Width of the previous element with pfp. Used with sameAuthorAsBefore

    property alias innerWidth: row.width

    width: parent.width
    contentHeight: row.height

    Row {
        id: row
        //width: parent.width
        width: (sameAuthorAsBefore && appSettings.oneAuthor) ? Math.max(masterWidth, Math.min(parent.width-((appSettings.messagesLessWidth && sent) ? Theme.paddingLarge : 0), contentsLbl.implicitWidth)) :
                             (appSettings.sentBehaviour != "n") ? // If sent messages are reversed or right-aligned,
                             // parent width substracting padding if sent and less width for messages is enabled
                    Math.min(parent.width - ((appSettings.messagesLessWidth && sent) ? Theme.paddingLarge : 0),

                             // width of all elements, last one is what is larger - author or contets
                             profileIcon.width + iconPadding.width + leftPadding.width + Math.max(contentsLbl.implicitWidth, authorLbl.width))

                    // if sent messages are not specially aligned or reversed,
                    // parent width substracting padding if sent and less width for messages is enabled
                    : parent.width-((appSettings.messagesLessWidth && sent) ? Theme.paddingLarge : 0)
        height: (sameAuthorAsBefore && appSettings.oneAuthor) ? textContainer.height : childrenRect.height
        // align right if sent and set to reversed/right aligned
        anchors.right: (sent && appSettings.sentBehaviour != "n") ? parent.right : undefined
        // reverse if sent and set to reversed
        layoutDirection: (sent && appSettings.sentBehaviour == "r") ? Qt.RightToLeft : Qt.LeftToRight

        Item { id: leftPadding; height: 1; width: switch (appSettings.messagesPadding) {
           default: case "n": return 0
           case "s": return sent ? Theme.paddingLarge : 0
           case "r": return sent ? 0 : Theme.paddingLarge
           case "a": return Theme.paddingLarge
        }
            visible: !(sameAuthorAsBefore && appSettings.oneAuthor) || appSettings.oneAuthorPadding != "n"
        }

        Image {
            id: profileIcon
            source: !(sameAuthorAsBefore && appSettings.oneAuthor) ? pfp : ""
            height: Theme.iconSizeLarge
            width: height
            visible: !(sameAuthorAsBefore && appSettings.oneAuthor) || appSettings.oneAuthorPadding == "p"
            opacity: (!(sameAuthorAsBefore && appSettings.oneAuthor) || appSettings.oneAuthorPadding == "p") ? 1 : 0

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
            // visible the same as for authorLbl or profileIcon; but if oneAuthorPadding is enabled then ignore everything and set to true
            visible: !(sameAuthorAsBefore && appSettings.oneAuthor) || appSettings.oneAuthorPadding == "n";
        Component.onCompleted: if (!visible) width = 0
        }

        Column {
            id: textContainer
            width: (sameAuthorAsBefore && appSettings.oneAuthor) ? parent.width - (profileIcon.width + iconPadding.width + leftPadding.width) :
                (appSettings.sentBehaviour == "a") ? // If sentBehaviour is right-aligned,
                             // ListItem width substracting all other elements width except us (textContainer)
                    Math.min(parent.width - (profileIcon.width + iconPadding.width + leftPadding.width),

                             Math.max(contentsLbl.paintedWidth, authorLbl.width))
                      // ListItem width substracting all other elements width except us (textContainer)
                    : parent.width - (profileIcon.width + iconPadding.width + leftPadding.width)
            Label {
                id: authorLbl
                text: author
                color: Theme.secondaryColor
                visible: !(sameAuthorAsBefore && appSettings.oneAuthor)
            }

            Label {
                id: contentsLbl
                text: contents
                wrapMode: Text.Wrap
                width: Math.min(parent.width, implicitWidth)
                               // if sent, sentBehaviour is set to reversed or right-aligned, and aligning text is enabled
                anchors.right: (sent && appSettings.sentBehaviour != "n" && appSettings.alignMessagesText)
                               ? parent.right : undefined
            }

            Item { height: !(sameAuthorAsBefore && appSettings.oneAuthor) ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
        }
    }
}
