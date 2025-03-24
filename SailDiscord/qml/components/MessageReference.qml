import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property var reference

    property var _resolvedReference
    property var _resolvedType
    property var _resolvedUpdater: function() {}

    property var jump: function() { return false } // Should return true if reference was found in messages model and false if not, takes message ID as the argument

    id: root
    width: parent.width
    contentHeight: column.height

    Column {
        id: column
        width: parent.width - Theme.horizontalPageMargin*2
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            id: row
            width: parent.width
            spacing: Theme.paddingLarge

            Icon {
                id: icon
                width: Theme.iconSizeMedium
                height: width
                source: switch (reference.type) {
                        case 1: return "image://theme/icon-m-rotate-right"
                        case 2: return "image://theme/icon-m-message-forward"
                        default: return "image://theme/icon-m-question"
                        }
            }

            Loader {
                id: infoLoader
                width: parent.width - icon.width - row.spacing*1
                anchors.verticalCenter: parent.verticalCenter

                Component {
                    id: systemItem
                    SystemMessageItem {
                        _model: _resolvedReference
                        label.color: Theme.secondaryColor
                        highlightColor: Theme.secondaryHighlightColor
                        enabled: false
                    }
                }

                Component {
                    id: defaultInfoItem
                    Label {
                        text: _resolvedReference.author
                        truncationMode: TruncationMode.Fade
                        color: Theme.secondaryHighlightColor
                    }
                }

                Component {
                    id: failedInfoItem
                    Row {
                        width: parent.width
                        spacing: children[0].visible ? Theme.paddingMedium : 0
                        Icon {
                            source: "image://theme/icon-m-" + (reference.state == 1 ? "delete" : "warning")
                            anchors.verticalCenter: parent.verticalCenter
                            visible: reference.state != 3
                        }

                        Label {
                            text: switch(reference.state) {
                                  case 1: return qsTr("Original message was deleted")
                                  case 3: return qsTr("Forwarded message")
                                  default: return qsTr("Reference failed to load")
                                  }

                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: Theme.fontSizeExtraSmall
                            truncationMode: TruncationMode.Fade

                            color: Theme.secondaryHighlightColor
                            font.italic: true
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.children[0].width - parent.spacing*1
                        }
                    }
                }
            }
        }

        Loader {
            id: contentLoader
            width: parent.width

            Component {
                id: defaultItem
                Label {
                    width: parent.width
                    textFormat: Text.RichText
                    text: _resolvedReference.formattedContents
                    wrapMode: Text.Wrap
                    color: highlighted ? Theme.highlightColor : Theme.secondaryColor
                }
            }
        }
    }

    Component.onCompleted: {
        if (reference.type == 0 || !root) return
        if (reference.state == 0 || reference.state == 1) {
            infoLoader.sourceComponent = failedInfoItem
            return
        }
        _resolvedType = shared.convertCallbackType(reference.resolvedType)
        shared.constructMessageCallback(_resolvedType, undefined, undefined, function(__, data) {_resolvedReference = data}).apply(null, reference.resolved)
        _resolvedReference.attachments = shared.attachmentsToListModel(root, _resolvedReference.attachments)
        contentLoader.sourceComponent = null // reload
        switch (_resolvedType) {
        case "":
            infoLoader.sourceComponent = reference.state == 3 ? failedInfoItem : defaultInfoItem
            contentLoader.sourceComponent = defaultItem
            break
        case "unknown":
            contentLoader.sourceComponent = appSettings.defaultUnknownMessages ? defaultItem : systemItem
            infoLoader.sourceComponent = appSettings.defaultUnknownMessages ? (reference.state == 3 ? failedInfoItem : defaultInfoItem) : undefined
            break
        default: infoLoader.sourceComponent = systemItem
        }
    }

    menu: Component { ContextMenu {
        hasContent: children[0].visible && children[1].visible

        MenuItem { text: qsTranslate("AboutUser", "About", "User")
            visible: !!_resolvedReference && _resolvedReference.userid != '-1' && !!_resolvedReference.userid
            onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"), { userid: _resolvedReference.userid, name: _resolvedReference.author, icon: _resolvedReference.avatar, nicknameGiven: _resolvedReference.flags.nickAvailable })
        }

        MenuItem { text: qsTr("Copy")
            onClicked: Clipboard.text = _resolvedReference.contents
            visible: !!_resolvedReference && !!_resolvedReference.contents
        }
    }}

    onClicked: if ((reference.state == 2 || reference.state == 3) && !jump(_resolvedReference.messageId)) pageStack.push(referencePage, {setResolvedUpdater: function(updater){ _resolvedUpdater = updater }})
    on_ResolvedReferenceChanged: _resolvedUpdater()
    on_ResolvedTypeChanged: _resolvedUpdater()
    Component {
        id: referencePage
        Page {
            property var setResolvedUpdater
            Component.onCompleted: setResolvedUpdater(pageLoader.updateSource)
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: pageColumn.height
                Column {
                    id: pageColumn
                    width: parent.width
                    PageHeader { title: qsTr("Reply") }

                    Loader {
                        id: pageLoader
                        width: parent.width

                        function updateSource() {
                            var args = {userid: _resolvedReference.userid,
                                contents: _resolvedReference.contents,
                                formattedContents: _resolvedReference.formattedContents,
                                author: _resolvedReference.author,
                                pfp: _resolvedReference._pfp,
                                sent: _resolvedReference.sent,
                                date: _resolvedReference.date,
                                sameAuthorAsBefore: false,
                                masterWidth: -1,
                                masterDate: new Date(1),
                                attachments: _resolvedReference.attachments,
                                reference: _resolvedReference.reference,
                                flags: _resolvedReference.flags}
                            switch (_resolvedType) {
                            case '': setSource("MessageItem.qml", args);break
                            case 'unknown': if (appSettings.defaultUnknownMessages) setSource("MessageItem.qml", args);else sourceComponent = systemItem;break
                            default: sourceComponent = systemItem
                            }
                        }
                        Component.onCompleted: updateSource()

                        Component {
                            id: systemItem
                            SystemMessageItem { _model: _resolvedReference; label.horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
            }
        }
    }
}
