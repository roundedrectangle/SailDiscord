import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../modules/Opal/Tabs"

TabView {
    id: root
    anchors.fill: parent
    tabBarPosition: Qt.AlignBottom
    currentIndex: 1

    property string username
    property var dmModel
    property var serversModel
    property bool loading

    Tab {
        title: qsTr("DMs")
        Component {
            TabItem {
                flickable: dmsContainer
                SilicaFlickable {
                    id: dmsContainer
                    anchors.fill: parent
                    PullDownMenu {
                        visible: !root.loading
                        MenuItem {
                            text: qsTr("Refresh")
                            onClicked: python.refresh()
                        }
                    }

                    PageHeader {
                        id: header
                        _titleItem.textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                        title: username
                    }
                    DMsView {
                        anchors {
                            top: header.bottom
                            bottom: parent.bottom
                        }
                        model: dmModel
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
                SilicaFlickable {
                    id: serversContainer
                    anchors.fill: parent
                    PullDownMenu {
                        visible: !root.loading
                        MenuItem {
                            text: qsTr("Refresh")
                            onClicked: python.refresh()
                        }
                    }
                    PageHeader {
                        id: header
                        _titleItem.textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                        title: username
                    }

                    SilicaListView {
                        width: parent.width
                        anchors {
                            top: header.bottom
                            bottom: parent.bottom
                        }
                        clip: true
                        model: serversModel
                        VerticalScrollDecorator {}

                        delegate: Loader {
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
    }

    Tab {
        title: qsTr("Me")

        Component {
            TabItem {
                id: tabItem
                flickable: morePage.flickable
                //topMargin: -(parent._ctxTopMargin || _ctxTopMargin || 0) // a bug occuring when using with Opal.About: top margin goes away for some reason, and gets the header...
                property string _username: username
                property string _avatar: avatar

                AboutUserPage {
                    parent: null
                    anchors.fill: parent
                    flickable.parent: tabItem
                    id: morePage
                    isClient: true
                    name: _username
                    icon: avatar
                    showSettings: false
                    loading: root.loading
                    _busyIndicator.visible: false

                    PullDownMenu {
                        parent: morePage.flickable
                        MenuItem {
                            text: qsTranslate("AboutApp", "About Sailcord", "App")
                            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                        }
                        MenuItem {
                            text: qsTr("Settings")
                            onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                        }
                    }
                }
            }
        }
    }
}
