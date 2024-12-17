import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/Tabs"

SilicaFlickable {
    anchors.fill: parent

    property string username
    property string avatar
    property var dmModel
    property var serversModel
    property int status
    property bool onMobile

    property int serverIndex: -1 // -1: DMs
    property int folderIndex: -1
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
            text: qsTr("Refresh")
            onClicked: python.refresh()
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
                    }
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
                        property bool selected: ((ListView.view && ListView.view.parent.folderIndex)
                                                 ? (serverIndex == ListView.view.parent.folderIndex && folderIndex == index)
                                                 : (serverIndex == index))

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
                            Item {
                                id: serverImage
                                width: parent.width - indicatorRectangle.width
                                height: width
                                ListImage {
                                    icon: image
                                    extendedRadius: selected
                                    anchors {
                                        fill: parent
                                        margins: Theme.paddingSmall
                                    }
                                    errorString: name
                                    anchors.centerIn: parent
                                    enabled: false
                                }
                            }
                        }

                        onClicked: {
                            if (ListView.view && ListView.view.parent.folderIndex) {
                                serverIndex = ListView.view.parent.folderIndex
                                folderIndex = index
                            } else {
                                serverIndex = index
                                folderIndex = -1
                            }
                        }
                        menu: Component { ContextMenu {
                            MenuItem {
                                Icon {
                                    source: "image://theme/icon-m-question"
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
                        }
                        ChannelsPage {
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

                onClicked: pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { isClient: true, name: username, icon: avatar })
            }
        }
    }
}
