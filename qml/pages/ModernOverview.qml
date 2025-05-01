import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/Tabs"

SilicaFlickable {
    anchors.fill: parent

    property string username
    property var avatar
    property var dmModel
    property var serversModel
    property int status
    property bool onMobile
    property bool loading

    property int serverIndex: -1 // -1: DMs; folder index when selected server is in a folder
    property int folderIndex: -1 // index inside a folder
    property var currentServer: serverIndex >= 0 ? (folderIndex >= 0 ? serversModel.get(serverIndex).servers.get(folderIndex) : serversModel.get(serverIndex)) : null

    PullDownMenu {
        MenuItem {
            text: qsTranslate("AboutApp", "About Sailcord", "App")
            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
        }
        MenuItem {
            text: qsTranslate("AboutServer", "About this server", "Server")
            visible: !!currentServer
            onClicked: pageStack.push(Qt.resolvedUrl("AboutServerPage.qml"), {
                serverid: currentServer._id,
                name: currentServer.name,
                icon: currentServer.image
            })
        }
        MenuItem {
            text: qsTr("Settings")
            onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            visible: loading
        }
        MenuItem {
            text: qsTr("Refresh")
            onClicked: py.refresh()
            visible: !loading
        }
    }

    Row {
        anchors.fill: parent
        visible: !loading
        SilicaListView {
            id: serverList
            width: Theme.itemSizeLarge + Theme.paddingMedium
            height: parent.height
            model: serversModel
            clip: true
            quickScroll: appSettings.modernUIServersQuickScroll
            VerticalScrollDecorator {}

            header: Row {
                width: parent.width
                Rectangle {
                    id: indicatorRectangle
                    width: Theme.paddingMedium
                    color: Theme.highlightColor
                    anchors.verticalCenter: parent.verticalCenter
                    height: width*2
                    radius: width/2
                    opacity: serverIndex == -1 ? 1 : 0
                    Behavior on opacity { FadeAnimator {} }
                }
                IconButton {
                    icon.source: "image://theme/icon-l-message"
                    width: parent.width
                    height: width
                    highlighted: serverIndex == -1 || down
                    onClicked: {
                        serverIndex = -1
                        folderIndex = -1
                        appConfiguration.modernLastServerId = "-1"
                    }
                }
            }

            Component.onCompleted: if (appConfiguration.modernLastServerId != '-1') {
                                       var i = serversModel.findIndexById(appConfiguration.modernLastServerId)
                                       serverIndex = i[0]
                                       folderIndex = i[1]
                                   }

            Connections {
                target: shared
                onServerAdded: if (serverId == appConfiguration.modernLastServerId) {
                                   serverIndex = mainIndex
                                   folderIndex = subIndex
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
                        id: serverItemInstance
                        width: parent.width
                        contentHeight: serverImage.height
                        property bool selected: (ListView.view && ListView.view.parent.folderIndex)
                                                 ? (serverIndex == ListView.view.parent.folderIndex && folderIndex == index)
                                                 : (serverIndex == index)

                        Row {
                            width: parent.width
                            Rectangle {
                                id: indicatorRectangle
                                width: Theme.paddingMedium
                                color: Theme.highlightColor
                                anchors.verticalCenter: parent.verticalCenter
                                height: width*2
                                radius: width/2
                                opacity: selected ? 1 : 0
                                Behavior on opacity { FadeAnimator {} }
                            }
                            Loader {
                                id: serverImage
                                width: parent.width - indicatorRectangle.width
                                height: width
                                sourceComponent: image.available ? serverImageComponent : serverImagePlaceholderComponent
                                Component {
                                    id: serverImageComponent
                                    ListImage {
                                        info: image
                                        extendedRadius: selected
                                        anchors {
                                            fill: parent
                                            margins: Theme.paddingSmall
                                            centerIn: parent
                                        }
                                        errorString: name
                                        enabled: false
                                        forceStatic: !selected
                                        //pauseAnimation: !selected // uses too much memory like this
                                    }
                                }
                                Component {
                                    id: serverImagePlaceholderComponent
                                    PlaceholderImage {
                                        text: name
                                        extendedRadius: selected
                                        anchors {
                                            fill: parent
                                            margins: Theme.paddingSmall
                                            centerIn: parent
                                        }
                                    }
                                }
                            }
                        }

                        function open() {
                            if (ListView.view && ListView.view.parent.folderIndex) {
                                serverIndex = ListView.view.parent.folderIndex
                                folderIndex = index
                            } else {
                                serverIndex = index
                                folderIndex = -1
                            }
                        }

                        onClicked: open()
                        menu: Component { ContextMenu {
                            MenuItem {
                                Icon {
                                    source: "image://theme/icon-m-about"
                                    anchors.centerIn: parent
                                }
                                onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutServerPage.qml"),
                                                          { serverid: _id, name: name, icon: image }
                                                          )
                            }
                            MenuItem {
                                Icon {
                                    source: "image://theme/icon-m-developer-mode"
                                    anchors.centerIn: parent
                                }
                                visible: appSettings.developerMode
                                onClicked: Clipboard.text = serverid
                            }
                        } }
                    }
                }

                Component {
                    id: serverFolderComponent
                    ColumnView {
                        width: parent.width
                        model: _servers
                        property int folderIndex: index
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
                    Item {
                        id: channelComponentItem
                        anchors.fill: parent
                        PageHeader {
                            id: channelComponentHeader
                            title: currentServer ? currentServer.name : ''
                            titleColor: Theme.highlightColor
                            MouseArea {
                                anchors.fill: parent
                                onClicked: openAbout()
                            }
                        }
                        ChannelsPage {
                            id: channelComponentPage
                            channelList.parent: channelComponentItem
                            _fillParent: false
                            channelList.width: parent.width
                            channelList.y: channelComponentHeader.y + channelComponentHeader.height
                            channelList.height: channelComponentItem.height - channelComponentHeader.height

                            channelList.onPullDownMenuChanged: channelList.pullDownMenu.visible = false
                            channelList.header: null
                            channelList.clip: true

                            name: currentServer ? currentServer.name : ''
                            icon: currentServer ? currentServer.image : ''
                            serverid: currentServer ? currentServer._id : ''
                            onServeridChanged: appConfiguration.modernLastServerId = serverid
                            Component.onCompleted: serveridChanged()
                        }
                    }
                }
                Component {
                    id: dmsComponent
                    DMsView {
                        anchors.fill: parent
                        model: dmModel
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
                        info: avatar
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

                onClicked: pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { isClient: true, name: username, icon: avatar })
            }
        }
    }
}
