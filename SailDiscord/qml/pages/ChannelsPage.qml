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

    SilicaListView {
        id: channelList
        model: chModel
        anchors.fill: parent

        header: PageHeader {
            title: name
        }

        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutServer", "About", "Server")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                    serverid: serverid,
                    name: name,
                    icon: icon,
                    memberCount: memberCount
                })
            }
        }

        section {
            property: "categoryname"
            delegate: SectionHeader {
                text: section
            }
        }

        delegate: ListItem {
            width: parent.width
            Row {
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.horizontalCenter: parent.horizontalCenter
                Icon {
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

                Item { height: 1; width: Theme.paddingLarge; }

                Label {
                    text: name
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

        Component.onCompleted: {
            python.setHandler('channel'+serverid, function (_categoryid, _categoryname, _id, _name, _haspermissions, _icon, _textSendingAllowed) {
                if (!_haspermissions && !appSettings.ignorePrivate) return;
                append({'categoryid': _categoryid, categoryname: _categoryname, channelid: _id, name: _name, icon: _icon, hasPermissions: _haspermissions, textSendPermissions: _textSendingAllowed})
            })
            python.requestChannels(serverid)
        }
    }

    Component {
        id: comingSoonPage
        Page {
            property string channelType
            SilicaFlickable {
                ViewPlaceholder {
                    enabled: true
                    text: qsTr("Channel unsupported")
                    hintText: channelType
                }
            }
        }
    }
}
