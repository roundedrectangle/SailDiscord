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
            loading = true
            python.login(appConfiguration.token)
        }

        if (!appConfiguration.usernameTutorialCompleted) completeTutorialTimer.start()
    }

    Connections {
        target: appConfiguration
        onTokenChanged: updatePage()
        onUsernameTutorialCompletedChanged: updatePage()
    }

    Component.onCompleted: {
        python.init(function(u) {
            loading = false
            username = u
        }, serversModel.append, serversModel.append, function() {
            serversModel.clear()
            username = ""
            updatePage()
        })
        updatePage()
    }

    SilicaListView {
        id: firstPageContainer
        anchors.fill: parent

        VerticalScrollDecorator {}
        BusyLabel { running: loading }

        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutApp", "About", "App")
                onClicked: pageStack.push("AboutPage.qml")
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push("SettingsPage.qml")
            }
            MenuItem {
                text: qsTr("Refresh servers")
                onClicked: python.refresh()
            }
        }

        header: PageHeader {
            title: username

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { isClient: true, name: username, icon: "" })
            }
            TapInteractionHint {
                id: tapHint
                anchors.centerIn: parent
                taps: 1
                running: !appConfiguration.usernameTutorialCompleted
            }
        }

        InteractionHintLabel {
            id: hintText
            anchors.bottom: parent.bottom
            text: "Tap your username to access information"
            Behavior on opacity { FadeAnimation {} }
            visible: opacity > 0
            opacity: appConfiguration.usernameTutorialCompleted ? 0 : 1
        }

        Timer {
            id: completeTutorialTimer
            interval: 4000
            onTriggered: appConfiguration.usernameTutorialCompleted = true
        }

        model: serversModel

        delegate: Loader {
            // TODO: fix folders sometimes not working
            sourceComponent: folder ? serverFolderComponent : serverItemComponent
            width: parent.width
            property var _color: folder ? color : undefined
            property var _servers: folder ? servers : undefined
            Component {
                id: serverItemComponent
                ServerListItem {
                    serverid: _id
                    title: name
                    icon: image
                }
            }

            Component {
                id: serverFolderComponent
                Column {
                    width: parent.width
                    SectionHeader {
                        id: folderHeader
                        visible: name
                        color: _color == "" ? palette.highlightColor : _color
                        text: name
                    }
                    Row {
                        width: parent.width
                        Item {
                            width: Theme.paddingLarge
                            height: parent.height
                            Rectangle {
                                width: Theme.paddingSmall
                                color: folderHeader.color
                                height: parent.height
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        ColumnView {
                            model: _servers
                            delegate: serverItemComponent
                            itemHeight: Theme.itemSizeLarge
                        }
                    }
                }
            }
        }

        section {
            property: "_id"
            delegate: Loader {
                width: parent.width
                sourceComponent: section == serversModel.get(0)._id ? undefined : separatorComponent
                Component {
                    id: separatorComponent
                    Separator {
                        color: Theme.primaryColor
                        width: parent.width
                        horizontalAlignment: Qt.AlignHCenter
                    }
                }
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
