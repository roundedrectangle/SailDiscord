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

    SilicaListView {
        id: channelList
        model: chModel
        anchors.fill: _fillParent ? parent : undefined

        header: PageHeader { title: name }
        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutServer", "About this server", "Server")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                    serverid: serverid,
                    name: name,
                    icon: icon
                })
            }
        }

        section {
            property: "categoryname"
            delegate: SectionHeader { text: section }
        }

        delegate: ListItem {
            width: parent.width
            Row {
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Icon { id: channelIcon
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
                }
            }

            onClicked: {
                if (!hasPermissions) return
                switch (icon) {
                case "text": case "news": case "name": pageStack.push(Qt.resolvedUrl("MessagesPage.qml"),
                                {guildid: serverid, channelid: channelid, name: name, sendPermissions: textSendPermissions});break
                default: pageStack.push(comingSoonPage, {channelType: icon});break
                }
            }
        }
    }

    ListModel {
        id: chModel
        property int lastServerId: -1

        function reloadModel() {
            if (lastServerId >= 0) python.setHandler('channel'+lastServerId)
            clear()
            python.setHandler('channel'+serverid, function (_categoryid, _categoryname, _id, _name, _haspermissions, _icon, _textSendingAllowed) {
                if (!_haspermissions && !appSettings.ignorePrivate) return;
                append({'categoryid': _categoryid, categoryname: _categoryname, channelid: _id, name: _name, icon: _icon, hasPermissions: _haspermissions, textSendPermissions: _textSendingAllowed})
            })
            python.requestChannels(serverid)
        }
        Component.onCompleted: reloadModel()
    }
    onServeridChanged: chModel.reloadModel()

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
