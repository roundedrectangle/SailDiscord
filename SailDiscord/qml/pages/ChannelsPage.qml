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
        PageHeader {
            title: name
        }
    }

    ListModel {
        id: model

        Component.onCompleted: {
            python.setHandler('category', function (_serverid, _id, _name) {
                if (_serverid != serverid) return;
                console.log("Got a new category! ID: "+_id+" NAME: "+_name)
            })
            python.requestCategories(serverid)
        }
    }
}
