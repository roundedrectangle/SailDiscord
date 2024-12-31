import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import '../modules/Opal/LinkHandler'
import '../modules/FancyContextMenu'

// TODO: width broken in demo mode (hint: the easy way is to remove aligned mode)
ListItem {
    property string contents
    property string formattedContents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client
    property bool sameAuthorAsBefore
    property date date
    property var attachments
    property var reference
    property string msgid: ''
    property bool managePermissions

    property string authorid // User-related
    property var flags

    property real masterWidth // Width of the previous element with pfp. Used with sameAuthorAsBefore
    property date masterDate // Date of previous element

    property bool _firstSameAuthor: switch(appSettings.messageGrouping) {
        case "n": return true
        case "a": return !sameAuthorAsBefore || referenceLoader.item != undefined
        case "d": return (!(sameAuthorAsBefore && (date - msgModel.get(index+1)._date) < 300000) /*5 minutes*/) || referenceLoader.item != undefined
    }
    property real _infoWidth: profileIcon.width + iconPadding.width + leftPadding.width

    property alias innerWidth: row.width

    property bool showRequestableOptions: true
    signal editRequested
    signal deleteRequested
    signal replyRequested

    id: root
    width: parent.width
    contentHeight: column.height

    Column {
        id: column
        width: parent.width

        Loader {
            id: referenceLoader
            width: parent.width
            height: item == undefined ? 0 : item.implicitHeight
            asynchronous: true
            Component.onCompleted: if (reference.type == 1) setSource(Qt.resolvedUrl("MessageReference.qml"), {reference: root.reference})
        }

        Row {
            id: row
            width: parent.width - Theme.paddingLarge
            height: !_firstSameAuthor ? textContainer.height : implicitHeight//childrenRect.height
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
                highlightOnClick: true
                onClicked: openAboutUser()
                enabled: _firstSameAuthor && showRequestableOptions && authorid != '-1'
                disableAnimations: true
            }

            Item { id: iconPadding; height: 1; width: visible ? Theme.paddingLarge : 0;
                // visible the same as for authorLbl or profileIcon; but if oneAuthorPadding is enabled then ignore everything and set to true
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n";
            }

            Column {
                id: textContainer
                width: parent.width - _infoWidth

                Row {
                    // TODO: truncate large nicknames
                    id: infoRow
                    visible: _firstSameAuthor
                    spacing: Theme.paddingSmall
                    width: Math.min(parent.width, implicitWidth)//iconRow.width + authorLbl.width + timeLbl.width)
                    anchors.right: (sent && appSettings.sentBehaviour !== "n") ? parent.right : undefined

                    Row {
                        id: iconRow
                        spacing: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { source: "image://theme/icon-s-secure"; visible: flags.system }
                        Icon { source: "image://theme/icon-s-developer"; visible: flags.bot }
                    }

                    Label {
                        id: authorLbl
                        width: Math.min(parent.parent.width - iconRow.width - timeLbl.width - parent.spacing*2, implicitWidth)
                        text: author
                        color: flags.color ? flags.color : Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        id: timeLbl
                        text: Format.formatDate(date, Formatter.TimepointRelative)
                        color: Theme.secondaryHighlightColor
                    }
                }

                Label {
                    // LinkedLabel formats tags so they are appeared in plain text. While there are workarounds, they would break with markdown support
                    wrapMode: Text.Wrap
                    textFormat: appSettings.unformattedText ? Text.PlainText : Text.RichText
                    text: formattedContents
                    width: parent.width
                                      // if sent, sentBehaviour is set to reversed or right-aligned, and aligning text is enabled
                    horizontalAlignment: (sent && appSettings.sentBehaviour !== "n" && appSettings.alignMessagesText) ? Text.AlignRight : undefined
                    onLinkActivated: LinkHandler.openOrCopyUrl(link)
                }

                Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
            }
        }

        AttachmentsPreview { model: root.attachments }

        Loader {
            width: parent.width
            height: item == undefined ? 0 : item.implicitHeight
            asynchronous: true
            Component.onCompleted: if (reference.type == 2) setSource(Qt.resolvedUrl("MessageReference.qml"), {reference: root.reference})
        }
    }

    function openAboutUser() {
        pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"),
                       { userid: authorid, name: author, icon: pfp }
                       )
    }

    menu: Component { FancyContextMenu {
        listItem: root

        FancyMenuRow {
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-clipboard"
                onClicked: Clipboard.text = contents
                visible: contents.length > 0
            }
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-edit"
                onClicked: editRequested()
                visible: sent && showRequestableOptions
            }
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-delete"
                onClicked: deleteRequested()
                visible: (sent || managePermissions) && showRequestableOptions
            }
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-message-reply"
                onClicked: replyRequested()
                visible: showRequestableOptions
            }
        }
        FancyAloneMenuItem {
            icon.source: "image://theme/icon-m-about"
            text: qsTranslate("AboutUser", "About this member", "User")
            visible: authorid != '-1'
            onClicked: openAboutUser()
        }
        FancyAloneMenuItem {
            text: qsTranslate("General", "Copy message ID")
            visible: appSettings.developerMode && msgid
            onClicked: Clipboard.text = msgid
        }
    }}

    Component {
        id: referenceComponent
        MessageReference { reference: root.reference }
    }
}
