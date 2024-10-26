import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property var reference
    property var _resolvedReference

    property string contents
    property string author
    property date date
    property bool loaded: false

    id: root
    width: parent.width - Theme.horizontalPageMargin*2
    contentHeight: row.height

    Row {
        id: row
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter

        Icon {
            id: icon
            width: Theme.iconSizeMedium
            height: width
            source: "image://theme/icon-m-message" + (reference.type == 2 ? "-reply" : (reference.type == 3 ? "-forward" : ""))
        }

        Loader {
            id: loader
            width: parent.width - icon.width

            Component {
                id: defaultItem
                Label {
                    width: parent.width
                    text: contents
                    wrapMode: Text.Wrap
                    color: Theme.secondaryColor
                }
            }

            Component {
                id: systemItem
                SystemMessageItem { _model: _resolvedReference; color: Theme.secondaryColor }
            }
        }
    }

    Component.onCompleted: {
        if (reference.type == 0) return
        python.getReference(reference.channel, reference.message, function(data) {
            shared.constructMessageCallback(shared.convertCallbackType(data[0]), undefined, undefined, function(_, data) {_resolvedReference = data}).apply(null, data.slice(1))
            switch (data[0]) {
            case "message":
                contents = data[11]
                loader.sourceComponent = defaultItem
                break
            case "unknownmessage":
                loader.sourceComponent = appSettings.defaultUnknownMessages ? defaultItem : systemItem
                break
            default: loader.sourceComponent = systemItem
            }
            loaded = true
        })
    }
}
