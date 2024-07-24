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
            height: Theme.itemSizeSmall
            visible: hasPermissions

            Label {
                text: name
                color: Theme.secondaryColor
            }
        }
    }

    ListModel {
        id: model

        Component.onCompleted: {
            python.setHandler('category', function (_serverid, _id, _name, _haspermissions) {
                if (_serverid != serverid) return;
                append({id: _id, name: _name, hasPermissions: _haspermissions})
            })
            python.requestCategories(serverid)
        }
    }
}
