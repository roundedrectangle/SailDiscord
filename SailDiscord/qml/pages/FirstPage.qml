import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"


Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool loading: true
    property bool loggingIn: false
    property string username: ""

    property alias serversModel: serversModel

    Timer {
        //credit: Fernschreiber
        id: openLoginDialogTimer
        interval: 0
        onTriggered: {
            pageStack.push(Qt.resolvedUrl("LoginDialog.qml"))
        }
    }

    function updatePage() {
        if (appConfiguration.token == "" && !loggingIn) {
            loggingIn = true
            loading = false
            openLoginDialogTimer.start()
        } else { // logged in, connect with python
            loggingIn = false
            python.login(appConfiguration.token)
        }
    }

    Connections {
        target: appConfiguration

        onTokenChanged: updatePage()
    }

    Component.onCompleted: {
        //appConfiguration.setToken("")
        console.log("Completed!")
        updatePage()
    }

    SilicaListView {
        id: firstPageContainer
        anchors.fill: parent

        BusyLabel {
            text: qsTr("Loading")
            running: loading
        }

        PullDownMenu {
            busy: loading

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push("AboutPage.qml")
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push("SettingsPage.qml")
            }
        }

        header: PageHeader {
            id: header_name
            title: username
        }

        model: serversModel

        delegate: ServerListItem {
            title: name
            icon: image

            onClicked: {
                pageStack.push(Qt.resolvedUrl("ChannelsPage.qml"), {
                    serverid: id,
                    name: name,
                    icon: icon,
                    memberCount: memberCount
                })
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("About")
                        onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                             serverid: id,
                             name: name,
                             icon: icon,
                             memberCount: memberCount
                         })
                    }
                }
            }

            Component.onCompleted: {
                console.log(image);
            }
        }
    }

    ListModel {
        id: serversModel

        function find(pattern) {
            for (var i = 0; i<count; i++) if (pattern(get(i))) return get(i)
            return null
        }

        function findById(_id) { return find(function (item) { return item.id === _id }) }
    }
}
