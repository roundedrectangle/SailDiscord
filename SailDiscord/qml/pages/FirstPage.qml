import QtQuick 2.0
import Sailfish.Silica 1.0


Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Second Page")
                onClicked: pageStack.push("SecondPage.qml")
            }

            MenuItem {
                text: qsTr("Login")
                onClicked: pageStack.push("LoginDialog.qml")
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height
        contentWidth: column.width

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column
        }

    }
}
