import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string serverid
    property string name
    property var icon
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

        delegate: ChannelItem {}
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
                py.reset('channel'+lastServerId, true)
                py.reset('channelUpdate'+lastServerId, true)
                py.call2('unset_server', lastServerId)
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
            py.call2('get_channels', serverid)
        }
        Component.onCompleted: reloadModel()
    }
    onServeridChanged: chModel.reloadModel()
    Component.onDestruction: {
        if (chModel.lastServerId != '-1') {
            py.setHandler('channel'+chModel.lastServerId, undefined)
            py.setHandler('channelUpdate'+chModel.lastServerId, undefined)
            py.call2('unset_server', chModel.lastServerId)
        }
        py.reset('channel'+serverid, true)
        py.reset('channelUpdate'+serverid, true)
        py.call2('unset_server', serverid)
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
