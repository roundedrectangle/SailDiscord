import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property var reference

    property var _resolvedReference
    property var _resolvedType

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
                        case 2: return "image://theme/icon-m-message-reply"
                        case 3: return "image://theme/icon-m-message-forward"
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
                        color: Theme.secondaryColor
                        highlightColor: Theme.secondaryHighlightColor
                    }
                }

                Component {
                    id: defaultInfoItem
                    Label {
                        text: _resolvedReference._author
                        truncationMode: TruncationMode.Fade
                        color: Theme.secondaryHighlightColor
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
                    text: _resolvedReference._contents
                    wrapMode: Text.Wrap
                    color: Theme.secondaryColor
                }
            }
        }
    }

    Component.onCompleted: {
        if (reference.type == 0) return
        python.getReference(reference.channel, reference.message, function(data) {
            if (!root || !data) return
            _resolvedType = shared.convertCallbackType(data[0])

            shared.constructMessageCallback(_resolvedType, undefined, undefined, function(__, data) {_resolvedReference = data}).apply(null, data.slice(1))
            switch (data[0]) {
            case "message":
                infoLoader.sourceComponent = defaultInfoItem
                contentLoader.sourceComponent = defaultItem
                break
            case "unknownmessage":
                contentLoader.sourceComponent = appSettings.defaultUnknownMessages ? defaultItem : systemItem
                infoLoader.sourceComponent = appSettings.defaultUnknownMessages ? defaultInfoItem : undefined
                break
            default: infoLoader.sourceComponent = systemItem
            }
        })
    }

    /*Component { // TODO
        id: referencePage
        Page {
            SilicaFlickable {
                Loader {
                    width: parent.width
                    sourceComponent:
                        switch (_resolvedType) {
                        case '': return defaultItem
                        case 'unknown': return appSettings.defaultUnknownMessages ? defaultItem : systemItem
                        default: return systemItem
                        }

                    Component {
                        id: defaultItem
                        MessageItem {
                            authorid: _resolvedReference.userid
                            contents: _resolvedReference._contents
                            author: _resolvedReference._author
                            pfp: _resolvedReference._pfp
                            sent: _resolvedReference._sent
                            date: _resolvedReference._date
                            sameAuthorAsBefore: false
                            masterWidth: -1
                            masterDate: new Date(1)
                            attachments: _resolvedReference._attachments
                            reference: _resolvedReference._ref
                        }
                    }

                    Component {
                        id: systemItem
                        SystemMessageItem { _model: _resolvedReference; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }
    }*/
}
