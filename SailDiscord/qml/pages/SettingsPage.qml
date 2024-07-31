import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: settingsPage
    allowedOrientations: Orientation.All


    SilicaFlickable {
        id: settingsContainer
        width: parent.width
        height: parent.height
        bottomMargin: Theme.paddingLarge
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: header
                title: qsTr("Settings")
            }

            ExpandingSectionGroup {
                anchors {
                    //top: header.bottom
                    //bottom: parent.bottom
                }

                //currentIndex: 0

                ExpandingSection {
                    id: section

                    //property int sectionIndex: model.index
                    title: qsTr("Behaviour")

                    content.sourceComponent: Column {
                        width: section.width

                        SectionHeader { text: qsTr("Servers list") }

                        TextSwitch {
                            text: qsTr("Keep empty space in servers without icons")
                            onCheckedChanged: {
                                appSettings.setEmptySpace(checked)
                            }

                            Component.onCompleted: {
                                checked = appSettings.emptySpace;
                            }
                        }

                        ComboBox {
                            label: qsTr("Size")
                            currentIndex: 0
                            menu: ContextMenu {
                                MenuItem { text: qsTr("large (default)") }
                                MenuItem { text: qsTr("extra large") }
                                MenuItem { text: qsTr("huge") }
                                MenuItem { text: qsTr("medium") }
                                //MenuItem { text: qsTr("small") }
                                //MenuItem { text: qsTr("extra small") }
                            }

                            Component.onCompleted: {
                                currentIndex = 0
                            }

                            onCurrentItemChanged: {
                                var res = function(){switch (currentItem.text) {
                                        case "large (default)": return "l"
                                        case "extra large": return "L"
                                        case "huge": return "h"
                                        case "medium": return "m"
                                        case "small": return "s"
                                        case "extra small": return "S"
                                    }}()
                                console.log(res)
                            }
                        }

                        SectionHeader { text: qsTr("Channels list") }

                        TextSwitch {
                            text: qsTr("Ignore private setting for channels and channel categories")
                            onCheckedChanged: {
                                appSettings.setIgnorePrivate(checked)
                            }

                            Component.onCompleted: {
                                checked = appSettings.ignorePrivate;
                            }
                        }

                        SectionHeader { text: qsTr("Messages") }

                        ComboBox {
                            id: sentMessagesBox
                            label: qsTr("Sent messages")
                            menu: ContextMenu {
                                MenuItem { text: qsTr("reversed (default)") }
                                MenuItem { text: qsTr("align right") }
                                MenuItem { text: qsTr("nothing") }
                            }

                            Component.onCompleted: {
                                currentIndex = 0
                            }

                            onCurrentItemChanged: {
                                var res = function(){switch (currentItem.text) {
                                        case "reversed (default)": return "r"
                                        case "align right": return "a"
                                        case "nothing": return "n"
                                    }}()
                                console.log(res)
                            }
                        }

                        TextSwitch {
                            text: qsTr("Less maximum width")
                            visible: sentMessagesBox.currentIndex != 2
                            description: qsTr("Makes the maximum width of a sent message smaller")

                            Component.onCompleted: {
                                checked = false
                            }
                        }

                        ComboBox {
                            label: qsTr("Extra padding")
                            currentIndex: 0
                            menu: ContextMenu {
                                MenuItem { text: qsTr("none (default)") }
                                MenuItem { text: qsTr("sent") }
                                MenuItem { text: qsTr("received") }
                                MenuItem { text: qsTr("all") }
                            }
                            description: qsTr("Sets for which messages extra padding should apply")

                            Component.onCompleted: {
                                currentIndex = 0
                            }

                            onCurrentItemChanged: {
                                var res = function(){switch (currentItem.text) {
                                        case "none (default)": return "n"
                                        case "sent": return "s"
                                        case "received": return "r"
                                        case "all": return "a"
                                    }}()
                                console.log(res)
                            }
                        }

                        ComboBox {
                            label: qsTr("Size")
                            currentIndex: 0
                            menu: ContextMenu {
                                MenuItem { text: qsTr("large (default)") }
                                MenuItem { text: qsTr("extra large") }
                                //MenuItem { text: qsTr("launcher") }
                                MenuItem { text: qsTr("medium") }
                                //MenuItem { text: qsTr("small") }
                                //MenuItem { text: qsTr("small plus") }
                                //MenuItem { text: qsTr("extra small") }
                            }

                            Component.onCompleted: {
                                currentIndex = 0
                            }

                            onCurrentItemChanged: {
                                var res = function(){switch (currentItem.text) {
                                        case "large (default)": return "l"
                                        case "extra large": return "L"
                                        case "launcher": return "a"
                                        case "medium": return "m"
                                        case "small": return "s"
                                        case "small plus": return "t"
                                        case "extra small": return "S"
                                    }}()
                                console.log(res)
                            }
                        }
                    }
                }

                ExpandingSection {
                    id: sessionSection

                    //property int sectionIndex: model.index
                    title: qsTr("Session")

                    content.sourceComponent: Column {
                        width: sessionSection.width

                        Button {
                            text: qsTr("Log out")
                            onClicked: {
                                appSettings.setToken("");
                            }
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
