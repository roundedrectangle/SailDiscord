import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property var reference

    property var _resolvedReference
    property var _resolvedType
    property var _resolvedUpdater: function(){console.warn("_resolvedUpdater was called but it isn't initialized yet! This should not happen")}

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
                        label.color: Theme.secondaryColor
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
                    textFormat: Text.RichText
                    text: _resolvedReference._contents
                    wrapMode: Text.Wrap
                    color: highlighted ? Theme.highlightColor : Theme.secondaryColor

                    Timer {
                        running: true
                        interval: 350
                        onTriggered: parent.text = shared.markdown(_resolvedReference._contents, Theme.secondaryHighlightColor)
                    }
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
            var listModel = Qt.createQmlObject('import QtQuick 2.0;ListModel{}', root)
            _resolvedReference._attachments.forEach(function(attachment, i) { listModel.append(attachment) })
            _resolvedReference._attachments = listModel
            contentLoader.sourceComponent = null // reload
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

    menu: Component { ContextMenu {
        MenuItem { text: qsTranslate("AboutUser", "About", "User")
            visible: !!_resolvedReference && _resolvedReference.userid != '-1' && !!_resolvedReference.userid
            onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutUserPage.qml"), { userid: _resolvedReference.userid, name: _resolvedReference._author, icon: _resolvedReference._pfp, nicknameGiven: _resolvedReference._flags.nickAvailable })
        }

        MenuItem { text: qsTr("Copy")
            onClicked: Clipboard.text = _resolvedReference._contents
            visible: !!_resolvedReference && !!_resolvedReference._contents
        }
    }}

    onClicked: pageStack.push(referencePage, {setResolvedUpdater: function(updater){ console.log("Resolved updater set...");_resolvedUpdater = updater }})
    on_ResolvedReferenceChanged: _resolvedUpdater()
    on_ResolvedTypeChanged: _resolvedUpdater()
    Component {
        id: referencePage
        Page {
            property var setResolvedUpdater
            Component.onCompleted: {setResolvedUpdater(pageLoader.updateSource);console.log(setResolvedUpdater, typeof setResolvedUpdater, JSON.stringify(setResolvedUpdater))}
            SilicaFlickable {
                anchors.fill: parent
                Loader {
                    id: pageLoader
                    width: parent.width

                    function updateSource() {
                        var args = {authorid: _resolvedReference.userid,
                            contents: _resolvedReference._contents,
                            author: _resolvedReference._author,
                            pfp: _resolvedReference._pfp,
                            sent: _resolvedReference._sent,
                            date: _resolvedReference._date,
                            sameAuthorAsBefore: false,
                            masterWidth: -1,
                            masterDate: new Date(1),
                            attachments: _resolvedReference._attachments,
                            reference: _resolvedReference._ref,
                            flags: _resolvedReference._flags}
                        switch (_resolvedType) {
                        case '': setSource("MessageItem.qml", args);break
                        case 'unknown': if (appSettings.defaultUnknownMessages) setSource("MessageItem.qml", args);else sourceComponent = systemItem;break
                        default: sourceComponent = systemItem
                        }
                    }
                    Component.onCompleted: updateSource()

                    /*Component {
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
                            flags: _resolvedReference._flags
                        }
                    }*/

                    Component {
                        id: systemItem
                        SystemMessageItem { _model: _resolvedReference; label.horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }
    }
}
