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

            Label {
                visible: !isCategory
                text: name

                Component.onCompleted: {
                    if (!visible) height = 0;
                }
            }

            Component.onCompleted: {
                python.setHandler('channel'+serverid+" "+categoryid, function (_id, _name, _haspermissions) {
                    if (!_haspermissions && !appSettings.ignorePrivate) return;
                    chModel.insert(index+1, {categoryid: _id, name: _name, isCategory: false})
                })
            }
        }
    }

    ListModel {
        id: chModel

        Component.onCompleted: {
            python.setHandler('category', function (_serverid, _id, _name, _haspermissions) {
                if ((_serverid != serverid) || (!_haspermissions && !appSettings.ignorePrivate)) return;
                append({categoryid: _id, name: _name, isCategory: true})

                python.requestChannels(serverid, _id)
            })
            python.requestCategories(serverid)
        }
    }
}
