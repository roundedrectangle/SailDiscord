import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string serverid
    property string name

    SilicaListView {
        id: channelList
        model: chModel
        anchors.fill: parent

        header: PageHeader {
            title: name
        }

        delegate: ListItem {
            property bool hadFirst: false
            width: parent.width

            SectionHeader {
                visible: isCategory
                id: sectionHeader
                text: categoryid == "-1" ? qsTr("No category") : name

                Component.onCompleted: {
                    if (!visible) height = 0;
                }
            }

            Row {
                visible: !isCategory
                Component.onCompleted: {
                    if (!visible) height = 0;
                }

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

            Component.onCompleted: {
                python.setHandler('channel'+serverid+" "+categoryid, function (_id, _name, _haspermissions, _icon) {
                    if (!_haspermissions && !appSettings.ignorePrivate) return;
                    chModel.insert(index+1, {categoryid: _id, name: _name, isCategory: false, icon: _icon})
                })

                updateNoCategory()
            }

            Connections {
                target: chModel
                onRowsInserted: {
                    updateNoCategory()
                }
            }

            function updateNoCategory() {
                if (chModel.get(index+1) == undefined) return;
                if ((categoryid == "-1") && (chModel.get(index+1).isCategory))
                    hidden = true
                else hidden = false
            }

            onClicked: {
                if (isCategory) return;
                pageStack.push(Qt.resolvedUrl("MessagesPage.qml"), {
                    channelid: categoryid,
                    name: name
                    //TODO: add channels here
                })
            }
        }
    }

    ListModel {
        id: chModel

        Component.onCompleted: {
            python.setHandler('category', function (_serverid, _id, _name, _haspermissions) {
                if ((_serverid != serverid) || (!_haspermissions && !appSettings.ignorePrivate)) return;
                append({categoryid: _id, name: _name, isCategory: true, icon: ""})

                python.requestChannels(serverid, _id)
            })
            python.requestCategories(serverid)
        }
    }
}
