import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/Tabs"

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool loading: true
    property string username: ""

    Timer {
        //credit: Fernschreiber
        id: openLoginDialogTimer
        interval: 0
        onTriggered: pageStack.push(Qt.resolvedUrl("LoginDialog.qml"))
    }

    function updatePage() {
        if (appConfiguration.token == "") {
            loading = false
            openLoginDialogTimer.start()
        } else { // logged in, connect with python
            loading = true
            python.login(appConfiguration.token)
        }

        //if (!appConfiguration.usernameTutorialCompleted) completeTutorialTimer.start()
    }

    Connections {
        target: appConfiguration
        onTokenChanged: updatePage()
        //onUsernameTutorialCompletedChanged: updatePage()
    }

    Component.onCompleted: {
        python.init(function(u) {
            loading = false
            username = u
        }, serversModel.append, dmModel.append, function() {
            serversModel.clear()
            dmModel.clear()
            username = ""
            updatePage()
        })
        updatePage()
    }

    TabView {
        anchors.fill: parent
        tabBarPosition: Qt.AlignBottom
        currentIndex: 1

        Tab {
            title: qsTr("DMs")
            Component {
                TabItem {
                    flickable: dmsContainer
                    property bool _loading: loading
                    SilicaListView {
                        id: dmsContainer
                        anchors.fill: parent
                        BusyLabel { running: _loading }
                        PullDownMenu {
                            MenuItem {
                                text: qsTr("Refresh")
                                onClicked: python.refresh()
                            }
                        }

                        header: PageHeader { title: username }

                        model: dmModel
                        delegate: ServerListItem {
                            serverid: '-1'
                            title: name
                            icon: image
                            defaultActions: false

                            onClicked: pageStack.push(Qt.resolvedUrl("MessagesPage.qml"), { guildid: '-2', channelid: dmChannel, name: name, sendPermissions: textSendPermissions, isDM: true, userid: _id, usericon: image })
                            menu: Component { ContextMenu {
                                MenuItem {text: qsTranslate("AboutUser", "About", "User")
                                    visible: _id != '-1'
                                    onClicked: pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { userid: _id, name: name, icon: image })
                                }
                            } }
                        }

                        section {
                            property: "_id"
                            delegate: Loader {
                                width: parent.width
                                sourceComponent: section == dmModel.get(0)._id ? undefined : separatorComponent
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
                }
            }
        }

        Tab {
            title: qsTr("Servers")
            Component {
                TabItem {
                    flickable: serversContainer
                    property bool _loading: loading
                    SilicaListView {
                        id: serversContainer
                        anchors.fill: parent
                        BusyLabel { running: _loading }
                        PullDownMenu {
                            MenuItem {
                                text: qsTr("Refresh")
                                onClicked: python.refresh()
                            }
                        }

                        VerticalScrollDecorator {}

                        header: PageHeader { title: username }
                            /*MouseArea {
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
                            text: qsTr("Tap your username to access information")
                            Behavior on opacity { FadeAnimation {} }
                            visible: opacity > 0
                            opacity: appConfiguration.usernameTutorialCompleted ? 0 : 1
                        }

                        Timer {
                            id: completeTutorialTimer
                            interval: 4000
                            onTriggered: appConfiguration.usernameTutorialCompleted = true
                        }*/

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
                }
            }
        }

        Tab {
            title: qsTr("Me")

            Component {
                TabItem {
                    id: tabItem
                    flickable: morePage.flickable
                    //topMargin: -(parent._ctxTopMargin || _ctxTopMargin || 0) // a bug occuring when using with Opal.About: top margin goes away for some reason, and gets the header...
                    property string _username: username

                    AboutUserPage {
                        parent: null
                        anchors.fill: parent
                        flickable.parent: tabItem
                        id: morePage
                        isClient: true
                        name: _username
                        icon: ""

                        //_pageHeaderItem.title: ""
                        PullDownMenu {
                            parent: morePage.flickable
                            MenuItem {
                                text: qsTranslate("AboutApp", "About", "App")
                                onClicked: pageStack.push("AboutPage.qml")
                            }
                            MenuItem {
                                text: qsTr("Settings")
                                onClicked: pageStack.push("SettingsPage.qml")
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: serversModel

        /*function find(pattern) {
            for (var i = 0; i<count; i++) if (pattern(get(i))) return get(i)
            return null
        }

        function findById(_id) { return find(function (item) { return item.id === _id }) }*/
    }

    ListModel { id: dmModel }
}
