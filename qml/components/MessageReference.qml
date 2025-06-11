import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import "../js/shared.js" as Shared

ListItem {
    id: root
    width: parent.width
    contentHeight: column.height

    property var reference
    property var jump: function() { return false } // Should return true if reference was found in messages model and false if not, takes message ID as the argument

    property var resolvedReference
    property var resolvedType

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
                source: switch (reference ? reference.type : -1) {
                        case -1: return ''
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
                        _model: resolvedReference
                        label.color: Theme.secondaryColor
                        highlightColor: Theme.secondaryHighlightColor
                        enabled: false
                    }
                }

                Component {
                    id: defaultInfoItem
                    Label {
                        text: resolvedReference.author
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
                    text: resolvedReference.formattedContents
                    wrapMode: Text.Wrap
                    color: highlighted ? Theme.highlightColor : Theme.secondaryColor
                }
            }
        }
    }

    function update() {
        if (!root || !reference || reference.type == 0) return
        if (reference.state == 0 || reference.state == 1) {
            infoLoader.sourceComponent = failedInfoItem
            return
        }
        resolvedType = Shared.convertCallbackType(reference.resolvedType)
        Shared.constructMessageCallback(resolvedType, undefined, undefined, function(__, data) {resolvedReference = data}).apply(null, reference.resolved)
        resolvedReference.attachments = Shared.arrayToListModel(root, resolvedReference.attachments)
        contentLoader.sourceComponent = null // reload
        switch (resolvedType) {
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

    Component.onCompleted: update()
    onReferenceChanged: update()

    menu: Component { ContextMenu {
        hasContent: children[0].visible && children[1].visible

        MenuItem { text: qsTranslate("AboutUser", "About", "User")
            visible: !!resolvedReference && resolvedReference.userid != '-1' && !!resolvedReference.userid
            onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"), { userid: resolvedReference.userid, name: resolvedReference.author, icon: resolvedReference.avatar, nicknameGiven: resolvedReference.flags.nickAvailable })
        }

        MenuItem { text: qsTr("Copy")
            onClicked: Clipboard.text = resolvedReference.contents
            visible: !!resolvedReference && !!resolvedReference.contents
        }
    }}

    onClicked: if ((reference.state == 2 || reference.state == 3) && !jump(resolvedReference.messageId))
                   pageStack.push(referencePage)
    Component {
        id: referencePage
        Page {
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
                            // var args = Shared.combineObjects(resolvedReference, {sameAuthorAsBefore: false, masterWidth: -1, masterDate: new Date(1)})
                            switch (resolvedType) {
                            case '':
                                setSource("MessageItem.qml", {_model: resolvedReference})
                                break
                            case 'unknown':
                                if (appSettings.defaultUnknownMessages)
                                    setSource("MessageItem.qml", {_model: resolvedReference})
                                else sourceComponent = systemItem
                                break
                            default: sourceComponent = systemItem
                            }
                        }
                        Component.onCompleted: updateSource()

                        Component {
                            id: systemItem
                            SystemMessageItem { _model: resolvedReference; label.horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
            }

            Connections {
                target: root
                onResolvedReferenceChanged: pageLoader.updateSource()
                onResolvedTypeChanged: pageLoader.updateSource()
            }
        }
    }
}
