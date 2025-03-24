import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import '../modules/Opal/LinkHandler'
import '../modules/FancyContextMenu'

// TODO: width broken in demo mode (hint: the easy way is to remove aligned mode)
ListItem {
    // Properties which are taken from the model:
    // author, messageId, avatar, contents, formattedContents, attachments, jumpUrl, reference, date,
    // sent // If the message is sent by the user connected to the client
    // userid, flags // User-related

    property bool sameAuthorAsBefore
    property bool sendPermissions
    property bool managePermissions

    property real masterWidth // Width of the previous element with pfp. Used with sameAuthorAsBefore
    property date masterDate // Date of previous element

    property bool _firstSameAuthor: switch(appSettings.messageGrouping) {
        case "n": return true
        case "a": return !sameAuthorAsBefore || referenceLoader.item != undefined
        case "d": return (!(sameAuthorAsBefore && (date - msgModel.get(index+1).date) < 300000) /*5 minutes*/) || referenceLoader.item != undefined
    }
    property real _infoWidth: profileIcon.width + iconPadding.width + leftPadding.width

    property alias innerWidth: row.width

    property bool showRequestableOptions: true
    signal editRequested
    signal deleteRequested
    signal replyRequested
    property var jumpToReference: function() { return false } // Should return true if reference was found in messages model and false if not, takes message ID as the argument

    property bool highlightStarted
    property bool _highlighting
    highlighted: down || menuOpen || _highlighting
    onHighlightStartedChanged: if (highlightStarted) {
        bgColorBehaviour.enabled = false
        _highlighting = true
        bgColorBehaviour.enabled = true
        _highlighting = false
    }

    Behavior on _backgroundColor {
        id: bgColorBehaviour
        enabled: false
        ColorAnimation {
            duration: 1000
            onRunningChanged: if (!running)
                bgColorBehaviour.enabled = false
        }
    }

    id: root
    width: parent.width
    contentHeight: column.height

    Column {
        id: column
        width: parent.width

        Item { height: !!attachments && attachments.count > 0 ? Theme.paddingLarge : 0; width: 1 }

        Loader {
            id: referenceLoader
            width: parent.width
            height: item == undefined ? 0 : item.implicitHeight
            asynchronous: true
            Component.onCompleted: if (reference.type == 1) setSource(Qt.resolvedUrl("MessageReference.qml"), {reference: root.reference})
            onStatusChanged: if (status == Loader.Ready) item.jump = jumpToReference
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
                icon: _firstSameAuthor ? avatar : ""
                visible: _firstSameAuthor || (appSettings.oneAuthorPadding === "p")
                opacity: _firstSameAuthor ? 1 : 0
                errorString: author
                highlightOnClick: true
                onClicked: openAboutUser()
                enabled: _firstSameAuthor && showRequestableOptions && userid != '-1'
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
                        textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                        MouseArea {
                            anchors.fill: parent
                            onClicked: openAboutUser()
                        }
                    }

                    Label {
                        id: timeLbl
                        text: Format.formatDate(date, Formatter.TimepointRelative)
                        color: Theme.secondaryHighlightColor
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Notices.show(date.toLocaleString(), Notice.Short, Notice.Center)
                        }
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
                    onLinkActivated: if (link == "sailcord://showEditDate" && flags.edit) Notices.show(qsTranslate("MessageItem", "Edited %1", "Date and time of a message edit. Showed when clicked on edited text").arg(date.toLocaleString()), Notice.Short, Notice.Center)
                                     else LinkHandler.openOrCopyUrl(link)
                    visible: contents.length > 0 || flags.edit
                }

                Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
            }
        }

        AttachmentsPreview { model: attachments }

        Loader {
            width: parent.width
            height: item == undefined ? 0 : item.implicitHeight
            asynchronous: true
            Component.onCompleted: if (reference.type == 2) setSource(Qt.resolvedUrl("MessageReference.qml"), {reference: root.reference})
            onStatusChanged: if (status == Loader.Ready) item.jump = jumpToReference
        }

        Item { height: attachments.count > 0 ? Theme.paddingLarge : 0; width: 1 }
    }

    function openAboutUser() {
        pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"),
                       { userid: userid, name: author, icon: avatar }
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
                visible: sendPermissions && showRequestableOptions
            }
        }
        FancyAloneMenuItem {
            icon.source: "image://theme/icon-m-about"
            text: qsTranslate("AboutUser", "About this member", "User")
            visible: userid != '-1'
            onClicked: openAboutUser()
        }
        MenuItem {
            text: qsTranslate("General", "Copy message ID")
            visible: appSettings.developerMode && messageId
            onClicked: Clipboard.text = messageId
        }
        MenuItem {
            text: qsTranslate("General", "Copy message link")
            visible: !!jumpUrl
            onClicked: Clipboard.text = jumpUrl
        }
        MenuItem {
            text: qsTranslate("General", "Copy formatted contents")
            visible: appSettings.developerMode
            onClicked: Clipboard.text = formattedContents
        }
    }}

    Component {
        id: referenceComponent
        MessageReference { reference: root.reference }
    }
}
