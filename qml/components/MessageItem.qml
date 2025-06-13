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
    // userid, flags, decoration // User-related

    property var _model: model // 1. For cases like `model: model.x` 2. For references (and possibly something else in the future)

    property bool sameAuthorAsBefore
    property bool sendPermissions
    property bool managePermissions

    property real masterWidth: -1 // Width of the previous element with avatar. Used with sameAuthorAsBefore
    property date masterDate: new Date(1) // Date of previous element

    property bool _firstSameAuthor: switch(appSettings.messageGrouping) {
        case "n": return true
        case "a": return !sameAuthorAsBefore || referenceLoader.item != undefined
        case "d": return (!(sameAuthorAsBefore && (_model.date - msgModel.get(index+1).date) < 300000) /*5 minutes*/) || referenceLoader.item != undefined
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

        Item { height: !!_model.attachments && _model.attachments.count > 0 ? Theme.paddingLarge : 0; width: 1 }

        Loader {
            id: referenceLoader
            width: parent.width
            height: item ? item.implicitHeight : 0
            asynchronous: true
            source: _model.reference.type == 1 ? Qt.resolvedUrl("MessageReference.qml") : ''
            onLoaded: {
                item.reference = _model.reference
                item.jump = jumpToReference
            }
        }

        Row {
            id: row
            width: parent.width - Theme.paddingLarge
            height: !_firstSameAuthor ? textContainer.height : implicitHeight//childrenRect.height
            // align right if sent and set to reversed/right aligned
            anchors.right: (_model.sent && appSettings.sentBehaviour !== "n") ? parent.right : undefined
            // reverse if sent and set to reversed
            layoutDirection: (_model.sent && appSettings.sentBehaviour === "r") ? Qt.RightToLeft : Qt.LeftToRight

            Item { id: leftPadding; height: 1; width: Theme.horizontalPageMargin
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n"
            }

            Item {
                id: profileIcon
                width: _firstSameAuthor || appSettings.oneAuthorPadding === 'p' ? Theme.iconSizeLarge : 0
                height: width
                Loader {
                    id: profileIconLoader
                    anchors.fill: parent
                    active: _firstSameAuthor && !!_model.avatar
                    sourceComponent: Component {
                        ListImage {
                            info: _model.avatar
                            errorString: _model.author
                            onClicked: openAboutUser()
                            enabled: _firstSameAuthor && showRequestableOptions && _model.userid != '-1'
                            disableAnimations: true
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: profileIconLoader.active && !!_model.decoration
                    sourceComponent: Component {
                        Asset {
                            anchors.fill: parent
                            info: _model.decoration
                        }
                    }
                }
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
                    anchors.right: (_model.sent && appSettings.sentBehaviour !== "n") ? parent.right : undefined

                    Row {
                        id: iconRow
                        spacing: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { source: "image://theme/icon-s-secure"; visible: _model.flags.system }
                        Icon { source: "image://theme/icon-s-developer"; visible: _model.flags.bot }
                    }

                    Label {
                        id: authorLbl
                        width: Math.min(parent.parent.width - iconRow.width - timeLbl.width - parent.spacing*2, implicitWidth)
                        text: _model.author
                        color: _model.flags.color ? _model.flags.color : Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                        MouseArea {
                            anchors.fill: parent
                            onClicked: openAboutUser()
                        }
                    }

                    Label {
                        id: timeLbl
                        text: Format.formatDate(_model.date, Formatter.TimepointRelative)
                        color: Theme.secondaryHighlightColor
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Notices.show(_model.date.toLocaleString(), Notice.Short, Notice.Center)
                        }
                    }
                }

                Label {
                    // LinkedLabel formats tags so they are appeared in plain text. While there are workarounds, they would break with markdown support
                    wrapMode: Text.Wrap
                    textFormat: appSettings.unformattedText ? Text.PlainText : Text.RichText
                    font.pixelSize: Theme.fontSizeSmall
                    text: _model.formattedContents
                    width: parent.width
                                      // if sent, sentBehaviour is set to reversed or right-aligned, and aligning text is enabled
                    horizontalAlignment: (_model.sent && appSettings.sentBehaviour !== "n" && appSettings.alignMessagesText) ? Text.AlignRight : undefined
                    onLinkActivated: if (link == "sailcord://showEditDate" && _model.flags.edit) Notices.show(qsTranslate("MessageItem", "Edited %1", "Date and time of a message edit. Showed when clicked on edited text").arg(_model.date.toLocaleString()), Notice.Short, Notice.Center)
                                     else LinkHandler.openOrCopyUrl(link)
                    visible: _model.contents.length > 0 || _model.flags.edit
                }

                Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
            }
        }

        AttachmentsPreview { model: _model.attachments }

        Loader {
            width: parent.width
            height: item ? item.implicitHeight : 0
            asynchronous: true
            source: _model.reference.type == 2 ? Qt.resolvedUrl("MessageReference.qml") : ''
            onLoaded: {
                item.reference = _model.reference
                item.jump = jumpToReference
            }
        }

        Item { height: _model.attachments.count > 0 ? Theme.paddingLarge : 0; width: 1 }
    }

    function openAboutUser() {
        pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"),
                       { userid: _model.userid, name: _model.author, icon: _model.avatar }
                       )
    }

    menu: Component { FancyContextMenu {
        listItem: root

        FancyMenuRow {
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-clipboard"
                onClicked: Clipboard.text = _model.contents
                visible: _model.contents.length > 0
            }
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-edit"
                onClicked: editRequested()
                visible: _model.sent && showRequestableOptions
            }
            FancyIconMenuItem {
                icon.source: "image://theme/icon-m-delete"
                onClicked: deleteRequested()
                visible: (_model.sent || managePermissions) && showRequestableOptions
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
            visible: _model.userid != '-1'
            onClicked: openAboutUser()
        }
        FancyAloneMenuItem {
            icon.source: "image://theme/icon-m-link"
            text: qsTranslate("General", "Copy message link")
            visible: !!_model.jumpUrl
            onClicked: Clipboard.text = _model.jumpUrl
        }
        MenuItem {
            text: qsTranslate("General", "Copy message ID")
            visible: appSettings.developerMode && _model.messageId
            onClicked: Clipboard.text = _model.messageId
        }
        MenuItem {
            text: qsTranslate("General", "Copy formatted contents")
            visible: appSettings.developerMode
            onClicked: Clipboard.text = _model.formattedContents
        }
    }}
}
