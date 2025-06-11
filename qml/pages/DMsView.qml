import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/shared.js" as Shared

SilicaListView {
    id: listView
    width: parent ? parent.width : Screen.width
    clip: true
    VerticalScrollDecorator {}
    property bool openLastSave: true

    Timer {
        id: closePageTimer
        interval: 0
        onTriggered: if (openLastSave && !!pageStack.nextPage() && pageStack.nextPage().serverid != '-1') pageStack.popAttached()
    }

    Component.onCompleted: closePageTimer.start()

    delegate: ServerListItem {
        serverid: '-1'
        title: name
        placeholderBase: iconBase
        icon: image
        defaultActions: false
        textHighlighted: unread
        mentionCount: mentions

        Timer {
            id: showTimer
            interval: 5
            onTriggered: show()
        }

        function show() { (openLastSave ? pageStack.pushAttached : pageStack.push)(Qt.resolvedUrl("MessagesPage.qml"), { guildid: '-2', channelid: dmChannel, name: name, sendPermissions: textSendPermissions, isDM: _id != '-1', isGroup: _id == '-1', userid: _id, usericon: image }) }
        Component.onCompleted: if (Shared.getLastChannel('-1') == dmChannel && openLastSave) showTimer.start()
        onClicked: {
            show()
            if (openLastSave) pageStack.navigateForward()
            Shared.setLastChannel('-1', dmChannel)
        }
        menu: Component { ContextMenu {
            MenuItem {
                text: qsTranslate("AboutUser", "About", "User")
                visible: _id != '-1'
                onClicked: pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { userid: _id, name: name, icon: image })
            }
            MenuItem {
                text: qsTranslate("General", "Copy channel ID")
                visible: appSettings.developerMode
                onClicked: Clipboard.text = dmChannel
            }
            MenuItem {
                text: qsTranslate("General", "Copy user ID")
                visible: appSettings.developerMode
                onClicked: Clipboard.text = _id
            }
        } }
    }

    section {
        property: "dmChannel"
        delegate: Loader {
            width: parent.width
            sourceComponent: section == listView.model.get(0).dmChannel ? undefined : separatorComponent
            Component {
                id: separatorComponent
                Separator {
                    color: Theme.primaryColor
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                }
            }
        }
    }

    Component.onDestruction: if (!!pageStack.nextPage()) pageStack.popAttached()
}
