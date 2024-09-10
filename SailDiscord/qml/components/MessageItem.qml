import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client
    property bool _sentLessWidth: appSettings.messagesLessWidth && sent
    property bool sameAuthorAsBefore
    property bool _firstSameAuthor: !(sameAuthorAsBefore && appSettings.oneAuthor)
    property real masterWidth // Width of the previous element with pfp. Used with sameAuthorAsBefore
    property date date

    property alias innerWidth: row.width

    width: parent.width
    contentHeight: row.height

    Row {
        id: row
        //width: parent.width
        width: !_firstSameAuthor ? Math.max(masterWidth, Math.min(parent.width-(_sentLessWidth ? Theme.paddingLarge : 0), profileIcon.width + iconPadding.width + leftPadding.width + contentsLbl.implicitWidth)) :(
                             (appSettings.sentBehaviour != "n") ? // If sent messages are reversed or right-aligned,
                             // parent width substracting padding if sent and less width for messages is enabled
                    Math.min(parent.width - (_sentLessWidth ? Theme.paddingLarge : 0),

                             // width of all elements, last one is what is larger - author or contets
                             profileIcon.width + iconPadding.width + leftPadding.width + Math.max(contentsLbl.implicitWidth, authorLbl.width))

                    // if sent messages are not specially aligned or reversed,
                    // parent width substracting padding if sent and less width for messages is enabled
                    : parent.width-(_sentLessWidth ? Theme.paddingLarge : 0))
        height: !_firstSameAuthor ? textContainer.height : childrenRect.height
        // align right if sent and set to reversed/right aligned
        anchors.right: (sent && appSettings.sentBehaviour != "n") ? parent.right : undefined
        // reverse if sent and set to reversed
        layoutDirection: (sent && appSettings.sentBehaviour == "r") ? Qt.RightToLeft : Qt.LeftToRight

        Item { id: leftPadding; height: 1; width: switch (appSettings.messagesPadding) {
           default: case "n": return 0
           case "s": return (visible && sent) ? Theme.paddingLarge : 0
           case "r": return (visible && sent) ? 0 : Theme.paddingLarge
           case "a": return visible ? Theme.paddingLarge : 0
        }
            visible: _firstSameAuthor || appSettings.oneAuthorPadding != "n"
        }

        Image {
            id: profileIcon
            source: _firstSameAuthor ? pfp : ""
            height: Theme.iconSizeLarge
            width: visible ? height : 0
            visible: _firstSameAuthor || (appSettings.oneAuthorPadding == "p")
            opacity: _firstSameAuthor ? 1 : 0

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

            onStatusChanged: if (status == Image.Error)
                Notices.show(qsTr("Error loading image %1. Please report this to developers").arg(author), Notice.Long, Notice.Top)

            ProgressCircle {
                id: progressCircle
                anchors.fill: parent
                visible: parent.status == Image.Loading

                Timer {
                    interval: 32
                    repeat: true
                    onTriggered: progressCircle.value = (progressCircle.value + 0.01) % 1.0
                    running: parent.parent.status == Image.Loading
                }
            }
        }

        Item { id: iconPadding; height: 1; width: visible ? Theme.paddingLarge : 0;
            // visible the same as for authorLbl or profileIcon; but if oneAuthorPadding is enabled then ignore everything and set to true
            visible: _firstSameAuthor || appSettings.oneAuthorPadding != "n";
        }

        Column {
            id: textContainer
            width: !_firstSameAuthor ? parent.width - (profileIcon.width + iconPadding.width + leftPadding.width) :
                ((appSettings.sentBehaviour == "a") ? // If sentBehaviour is right-aligned,
                             // ListItem width substracting all other elements width except us (textContainer)
                    Math.min(parent.width - (profileIcon.width + iconPadding.width + leftPadding.width),

                             Math.max(contentsLbl.paintedWidth, authorLbl.width))
                      // ListItem width substracting all other elements width except us (textContainer)
                    : (parent.width - (profileIcon.width + iconPadding.width + leftPadding.width)))
            Label {
                id: authorLbl
                text: author
                color: Theme.secondaryColor
                visible: _firstSameAuthor
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

            Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
        }
    }

    Component.onCompleted: {
        console.log(date)
    }
}
