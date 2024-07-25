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
        model: model
        anchors.fill: parent

        header: PageHeader {
            title: name
        }

        delegate: ListItem {
            width: parent.width
            //height: Theme.itemSizeSmall

            SectionHeader {
                id: sectionHeader
                text: name
            }

            SilicaListView { // TODO: add model for a specefic category here
                model: sectionModel
                anchors {
                    top: sectionHeader.bottom
                    bottom: parent.bottom
                }
                width: parent.width

                delegate: ListItem {
                    Label {
                        text: name
                    }
                }
            }

            ListModel {
                id: sectionModel

                Component.onCompleted: {
                    append({id: 0, name: "hello"})
                }
            }
        }
    }

    ListModel {
        id: model

        Component.onCompleted: {
            python.setHandler('category', function (_serverid, _id, _name, _haspermissions) {
                if ((_serverid != serverid) || (!_haspermissions && !appSettings.ignorePrivate)) return;
                append({id: _id, name: _name})
            })
            python.requestCategories(serverid)
        }
    }
}
