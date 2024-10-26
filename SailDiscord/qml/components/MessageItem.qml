import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string authorid
    property string contents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client
    property bool sameAuthorAsBefore
    property date date
    property var attachments
    property var reference

    property real masterWidth // Width of the previous element with pfp. Used with sameAuthorAsBefore
    property date masterDate // Date of previous element

    property bool _firstSameAuthor: switch(appSettings.messageGrouping) {
        case "n": return true
        case "a": return !sameAuthorAsBefore
        case "d": return !(sameAuthorAsBefore && (date - msgModel.get(index+1)._date) < 300000) // 5 minutes
    }
    property bool _sentLessWidth: sent ? Theme.paddingLarge : 0 // Width required to substract
    property real _infoWidth: profileIcon.width + iconPadding.width + leftPadding.width

    property alias innerWidth: row.width

    id: root
    width: parent.width
    contentHeight: column.height

    Column {
        id: column
        width: parent.width

        Loader {
            sourceComponent: reference['type'] == 2 || reference['type'] == 1 ? referenceComponent : null
            width: parent.width
            height: item == undefined ? 0 : item.contentHeight
            asynchronous: true
        }

        Row {
            id: row
            width: {
                if(_firstSameAuthor) {
                    if (appSettings.sentBehaviour !== "n")
                        return Math.min(parent.width - _sentLessWidth,
                                        _infoWidth + Math.max(contentsLbl.implicitWidth, infoRow.width));
                    else return parent.width-_sentLessWidth
                } else return Math.max(masterWidth,
                                       Math.min(parent.width-_sentLessWidth,
                                                _infoWidth + contentsLbl.implicitWidth))
            }
            height: !_firstSameAuthor ? textContainer.height : childrenRect.height
            // align right if sent and set to reversed/right aligned
            anchors.right: (sent && appSettings.sentBehaviour !== "n") ? parent.right : undefined
            // reverse if sent and set to reversed
            layoutDirection: (sent && appSettings.sentBehaviour === "r") ? Qt.RightToLeft : Qt.LeftToRight

            Item { id: leftPadding; height: 1; width: Theme.horizontalPageMargin
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n"
            }

            ListImage {
                id: profileIcon
                icon: _firstSameAuthor ? pfp : ""
                visible: _firstSameAuthor || (appSettings.oneAuthorPadding === "p")
                opacity: _firstSameAuthor ? 1 : 0
                errorString: author
            }

            Item { id: iconPadding; height: 1; width: visible ? Theme.paddingLarge : 0;
                // visible the same as for authorLbl or profileIcon; but if oneAuthorPadding is enabled then ignore everything and set to true
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n";
            }

            Column {
                id: textContainer
                width: parent.width - _infoWidth

                Row {
                    id: infoRow
                    visible: _firstSameAuthor
                    spacing: Theme.paddingSmall
                    Label {
                        id: authorLbl
                        text: author
                        color: Theme.secondaryColor
                    }

                    Label {
                        id: timeLbl
                        text: Format.formatDate(date, Formatter.TimepointRelative)
                        color: Theme.secondaryHighlightColor
                    }
                }

                Label {
                    id: contentsLbl
                    text: contents
                    wrapMode: Text.Wrap
                    width: parent.width
                                      // if sent, sentBehaviour is set to reversed or right-aligned, and aligning text is enabled
                    horizontalAlignment: (sent && appSettings.sentBehaviour !== "n" && appSettings.alignMessagesText) ? Text.AlignRight : undefined
                    Rectangle{anchors.fill:parent;color:"red"}
                }

                Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
            }
        }

        AttachmentsPreview { model: root.attachments }

        Loader {
            sourceComponent: reference['type'] == 3 ? referenceComponent : null
            width: parent.width
            height: item == undefined ? 0 : item.contentHeight
            asynchronous: true
        }
    }

    menu: Component { ContextMenu {
        MenuItem { text: qsTranslate("AboutUser", "About", "User")
            onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"), { userid: authorid, name: author, icon: pfp })
        }

        MenuItem { text: qsTr("Copy")
            onClicked: Clipboard.text = contents
            visible: contents.length > 0
        }
    }}

    Component {
        id: referenceComponent
        MessageReference { reference: root.reference }
    }
}
