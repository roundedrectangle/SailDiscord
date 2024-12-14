import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/Tabs"

Page {
    allowedOrientations: Orientation.All

    property bool loading: true
    property string username: ""
    property string avatar
    property int status: 0
    property bool onMobile: false

    Timer {
        //credit: Fernschreiber
        id: openLoginDialogTimer
        interval: 0
        onTriggered: pageStack.push(Qt.resolvedUrl("LoginDialog.qml"))
    }

    function updatePage() {
        if (appConfiguration.token == "") {
            // For log out
            serversModel.clear()
            dmModel.clear()
            username = ""
            avatar = ""
            status = 0
            onMobile = false

            loading = false
            openLoginDialogTimer.start()
        } else { // logged in, connect with python
            loading = true
            python.login(appConfiguration.token)
        }
    }

    Connections {
        target: appConfiguration
        onTokenChanged: updatePage()
    }

    Component.onCompleted: {
        python.init(function(u, i, s, m) {
            loading = false
            username = u
            avatar = i
            status = s
            onMobile = m
        }, serversModel.append, dmModel.append, function() {
            serversModel.clear()
            dmModel.clear()
            username = ""
            updatePage()
        })
        updatePage()
    }

    BusyLabel { running: loading }

    property int channelIndex: -1 // -1: DMs
    property var currentServer: channelIndex >= 0 ? serversModel.get(channelIndex) : null

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutServer", "About this server", "Server")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                    serverid: currentServer._id,
                    name: currentServer.name,
                    icon: currentServer.image
                })
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: python.refresh()
            }
        }

        Row {
            anchors.fill: parent
            visible: !loading
            SilicaListView {
                id: serverList
                width: Theme.itemSizeLarge
                height: parent.height
                model: serversModel
                VerticalScrollDecorator {}

                header: Column {
                    width: parent.width
                    Item { width:1;height: Theme.paddingLarge }
                    IconButton {
                        id: iconButton
                        icon.source: "image://theme/icon-l-message"
                        width: parent.width
                        height: width
                        onClicked: channelIndex = -1
                    }
                }

                delegate: Loader {
                    sourceComponent: folder ? serverFolderComponent : serverItemComponent
                    width: parent.width
                    height: item.implicitHeight
                    property var _color: folder ? color : undefined
                    property var _servers: folder ? servers : undefined
                    onStatusChanged: if (status == Loader.Ready) item.anchors.fill = item.parent

                    Component {
                        id: serverItemComponent
                        ListItem {
                            width: parent.width
                            contentHeight: serverImage.height

                            Item {
                                id: serverImage
                                width: parent.width
                                height: width
                                ListImage {
                                    icon: image
                                    anchors {
                                        fill: parent
                                        margins: Theme.paddingSmall
                                    }
                                    errorString: name
                                    anchors.centerIn: parent
                                    enabled: false
                                }
                            }

                            onClicked: channelIndex = index
                            menu: Component { ContextMenu {
                                MenuItem {
                                    Icon {
                                        source: "image://theme/icon-m-question"
                                        anchors.centerIn: parent
                                    }
                                    //text: qsTranslate("AboutServer", "About", "Server")
                                    onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutServerPage.qml"),
                                                              { serverid: _id, name: name, icon: image }
                                                              )
                                }
                            } }
                        }
                    }

                    Component {
                        id: serverFolderComponent
                            ColumnView {
                                width: parent.width
                                model: _servers
                                delegate: serverItemComponent
                                itemHeight: Theme.itemSizeLarge

                                Rectangle {
                                    anchors.fill: parent
                                    z: -1
                                    color: _color == "" ? palette.highlightColor : _color
                                    radius: parent.width / 2
                                    opacity: 0.2
                                }
                            }
                    }
                }
            }

            Item {
                width: parent.width - serverList.width
                height: parent.height

                Loader {
                    id: channelRoot
                    width: parent.width
                    anchors {
                        top: parent.top
                        bottom: me.top
                    }

                    sourceComponent: currentServer ? channelComponent : dmsComponent
                    Component {
                        id: channelComponent
                        ChannelsPage {
                            channelList.parent: channelRoot
                            channelList.onPullDownMenuChanged: channelList.pullDownMenu.visible = false
                            name: currentServer.name
                            icon: currentServer.image
                            serverid: currentServer._id
                        }
                    }
                    Component {
                        id: dmsComponent
                        Item {
                            id: dmsContainer
                            anchors.fill: parent

                            PageHeader { id: header; title: username }

                            SilicaListView {
                                width: parent.width
                                anchors {
                                    top: header.bottom
                                    bottom: parent.bottom
                                }
                                clip: true
                                model: dmModel
                                VerticalScrollDecorator {}

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

                BackgroundItem {
                    id: me
                    width: parent.width
                    anchors.bottom: parent.bottom
                    height: meContent.height
                    Row {
                        id: meContent
                        width: parent.width - Theme.paddingLarge*2
                        height: implicitHeight + Theme.paddingSmall*2
                        anchors.centerIn: parent
                        spacing: Theme.paddingLarge

                        ListImage {
                            id: meAvatar
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: false
                            icon: avatar
                        }

                        Column {
                            width: parent.width - meAvatar.width - parent.spacing*1
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                truncationMode: TruncationMode.Fade
                                text: username
                                color: Theme.highlightColor
                            }
                            Label {
                                truncationMode: TruncationMode.Fade
                                text: shared.constructStatus(status, onMobile)
                                color: Theme.secondaryHighlightColor
                            }
                        }
                    }
                }
            }
        }
    }
    /*TouchBlocker {
        anchors.fill: parent
        visible: false//loading
    }*/

    ListModel { id: serversModel }
    ListModel { id: dmModel }
}
