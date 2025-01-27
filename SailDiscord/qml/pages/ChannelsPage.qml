import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string serverid
    property string name
    property string icon
    property string memberCount

    property alias channelList: channelList
    property bool _fillParent: true

    function openAbout() {
        pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
            serverid: serverid,
            name: name,
            icon: icon
        })
    }

    function openChannel(m, background) {
        background = background == undefined ? false : background
        if (!m.hasPermissions) return
        switch (m.icon) {
        case "text": case "news": case "name": pageStack.pushAttached(Qt.resolvedUrl("MessagesPage.qml"),
                        {guildid: serverid, channelid: m.channelid, name: m.name, sendPermissions: m.textSendPermissions, managePermissions: m.managePermissions, topic: m.topic});break
        default: pageStack.pushAttached(comingSoonPage, {channelType: m.icon});break
        }
        if (!background) {
            shared.setLastChannel(serverid, m.channelid)
            pageStack.navigateForward()
        }
    }

    SilicaListView {
        id: channelList
        model: chModel
        anchors.fill: _fillParent ? parent : undefined

        header: PageHeader {
            title: name
            _titleItem.textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
            titleColor: Theme.highlightColor
            MouseArea {
                anchors.fill: parent
                onClicked: openAbout()
            }
        }
        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutServer", "About this server", "Server")
                onClicked: openAbout()
            }
        }

        section {
            property: "categoryname"
            delegate: SectionHeader {
                textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                text: section
            }
        }

        delegate: ListItem {
            width: parent.width
            contentHeight: row.height
            Row {
                id: row
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
                height: Theme.itemSizeSmall

                Icon { id: channelIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: {
                        switch (icon) {
                            case "voice":
                            case "stage_voice":
                                "image://theme/icon-m-browser-sound"
                                break
                            case "news":
                                "image://theme/icon-m-send"
                                break
                            case "private":
                                "image://theme/icon-m-device-lock"
                                break
                            case "text":
                                "image://theme/icon-m-edit"
                                break
                            case "forum":
                            case "directory":
                                "image://theme/icon-m-folder"
                                break
                            default:
                                "image://theme/icon-m-warning"
                                break
                        }
                    }
                    opacity: hasPermissions ? 1 : Theme.opacityLow
                }

                Label {
                    text: name
                    width: parent.width - channelIcon.width - channelUnreadCount.width - parent.spacing*2
                    truncationMode: TruncationMode.Fade
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                    highlighted: unread
                    opacity: hasPermissions ? 1 : Theme.opacityLow
                }

                Rectangle {
                    id: channelUnreadCount
                    visible: mentions > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: children[0].width + Theme.paddingSmall*2
                    height: children[0].height + Theme.paddingSmall*2
                    radius: height/2
                    color: Theme.highlightColor
                    Label {
                        text: mentions > 100000 ? '100k+' : mentions
                        color: Theme.primaryColor
                        anchors.centerIn: parent
                    }
                }
            }

            onClicked: openChannel(model)

            menu: Component { ContextMenu {
                    hasContent: appSettings.developerMode
                    MenuItem {
                        text: qsTranslate("General", "Copy channel ID")
                        visible: appSettings.developerMode
                        onClicked: Clipboard.text = channelid
                    }
                } }
        }
    }

    ListModel {
        id: chModel
        property string lastServerId: '-1'

        function findIndexById(id) {
            for(var i=0; i < count; i++)
                if (get(i).channelid == id) return i
            return -1
        }

        function reloadModel() {
            if (lastServerId == serverid) return
            if (lastServerId != '-1') {
                py.setHandler('channel'+lastServerId, undefined)
                py.setHandler('channelUpdate'+lastServerId, undefined)
                py.call2('unset_server', [lastServerId])
            }
            clear()
            if (!!pageStack.nextPage()) pageStack.popAttached()
            if (serverid == '') return
            lastServerId = serverid
            var last = shared.getLastChannel(serverid)
            py.setHandler('channel'+serverid, function (categoryid, categoryname, channelid, name, haspermissions, icon, textSendPermissions, managePermissions, topic, unread, mentions) {
                if (!haspermissions && !appSettings.ignorePrivate) return
                var m = {
                    categoryid: categoryid, categoryname: shared.emojify(categoryname), channelid: channelid, name: shared.emojify(name),
                    icon: icon, hasPermissions: haspermissions, textSendPermissions: textSendPermissions,
                    managePermissions: managePermissions, topic: shared.emojify(topic), unread: unread, mentions: mentions,
                }
                append(m)
                if (last == channelid) openChannel(m, true)
            })
            py.setHandler('channelUpdate'+serverid, function (channelid, unread, mentions) {
                var i = findIndexById(channelid)
                if (i >= 0) {
                    setProperty(i, 'unread', unread)
                    setProperty(i, 'mentions', mentions)
                }
            })
            py.requestChannels(serverid)
        }
        Component.onCompleted: reloadModel()
    }
    onServeridChanged: chModel.reloadModel()
    Component.onDestruction: {
        if (chModel.lastServerId != '-1') {
            py.setHandler('channel'+chModel.lastServerId, undefined)
            py.setHandler('channelUpdate'+chModel.lastServerId, undefined)
            py.call2('unset_server', [chModel.lastServerId])
        }
        py.setHandler('channel'+serverid, undefined)
        py.setHandler('channelUpdate'+serverid, undefined)
        py.call2('unset_server', [serverid])
        if (!!pageStack.nextPage() && pageStack.nextPage().serverid != '-1') pageStack.popAttached()
    }

    Component {
        id: comingSoonPage
        Page {
            property string channelType
            SilicaFlickable {
                anchors.fill: parent
                ViewPlaceholder {
                    enabled: true
                    text: qsTr("Channel unsupported")
                    hintText: channelType
                }
            }
        }
    }
}
