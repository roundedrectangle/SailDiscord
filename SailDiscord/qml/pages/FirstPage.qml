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

        if (!appConfiguration.usernameTutorialCompleted) completeTutorialTimer.start()
    }

    Connections {
        target: appConfiguration
        onTokenChanged: updatePage()
        onUsernameTutorialCompletedChanged: updatePage()
    }

    Component.onCompleted: updatePage()

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

        delegate: ServerListItem {
            title: name
            icon: image

            onClicked: {
                pageStack.push(Qt.resolvedUrl("ChannelsPage.qml"), {
                    serverid: _id,
                    name: name,
                    icon: icon,
                    memberCount: memberCount
                })
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTranslate("AboutServer", "About", "Server")
                        onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                             serverid: _id,
                             name: name,
                             icon: icon,
                             memberCount: memberCount
                         })
                    }
                }
            }
        }

        section {
            property: "modelIndex"
            delegate: Loader {
                width: parent.width
                sourceComponent:
                    if (!serversModel.get(Number(section)).folder ||
                            Object.keys(serversModel.get(Number(section)).folder).length == 0)
                        return section == 0 ? undefined : separatorComponent
                    else return folderComponent

                Component {
                    id: folderComponent
                    SectionHeader {
                        text: serversModel.get(Number(section)).folder.name
                    }
                }
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
