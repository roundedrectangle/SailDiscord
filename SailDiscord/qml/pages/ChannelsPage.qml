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
                        {guildid: serverid, channelid: m.channelid, name: m.name, sendPermissions: m.textSendPermissions, managePermissions: m.managePermissions});break
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
            delegate: SectionHeader { text: section }
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
                }

                Label {
                    text: name
                    width: parent.width - channelIcon.width - parent.spacing*1
                    truncationMode: TruncationMode.Fade
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
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

        function reloadModel() {
            if (lastServerId == serverid) return
            if (lastServerId != '-1') python.setHandler('channel'+lastServerId, undefined)
            clear()
            if (!!pageStack.nextPage()) pageStack.popAttached()
            if (serverid == '') return
            lastServerId = serverid
            var last = shared.getLastChannel(serverid)
            python.setHandler('channel'+serverid, function (_categoryid, _categoryname, _id, _name, _haspermissions, _icon, _textSendingAllowed, _managePermissions) {
                if (!_haspermissions && !appSettings.ignorePrivate) return
                var m = {categoryid: _categoryid, categoryname: _categoryname, channelid: _id, name: shared.emojify(_name), icon: _icon, hasPermissions: _haspermissions, textSendPermissions: _textSendingAllowed, managePermissions: _managePermissions}
                append(m)
                if (last == _id) openChannel(m, true)
            })
            python.requestChannels(serverid)
        }
        Component.onCompleted: reloadModel()
    }
    onServeridChanged: chModel.reloadModel()
    Component.onDestruction: {
        if (chModel.lastServerId != '-1') python.setHandler('channel'+chModel.lastServerId, undefined)
        python.setHandler('channel'+serverid, undefined)
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
