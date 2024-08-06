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
                                currentIndex = function(){switch (appSettings.serverSize) {
                                    case "l": return 0
                                    case "L": return 1
                                    case "h": return 2
                                    case "m": return 3

                                    case "s":
                                    case "S":
                                    default:
                                        appSettings.setServerSize("l")
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.setServerSize(function(){switch (currentItem.text) {
                                    case "large (default)": return "l"
                                    case "extra large": return "L"
                                    case "huge": return "h"
                                    case "medium": return "m"
                                    case "small": return "s"
                                    case "extra small": return "S"
                                }}())
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
                                currentIndex = function(){switch (appSettings.sentBehaviour) {
                                    case "r": return 0
                                    case "a": return 1
                                    case "n": return 2
                                    default:
                                        appSettings.setSentBehaviour("r")
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.setSentBehaviour(function(){switch (currentItem.text) {
                                    case "reversed (default)": return "r"
                                    case "align right": return "a"
                                    case "nothing": return "n"
                                }}())
                            }
                        }

                        TextSwitch {
                            text: qsTr("Less maximum width")
                            enabled: sentMessagesBox.currentIndex != 2
                            description: sentMessagesBox.currentIndex != 2 ?
                                             qsTr("Adds a padding to the left side of a sent message.")
                                           : qsTr("Set Sent messages to reversed or align right to enable.")

                            Component.onCompleted: {
                                checked = appSettings.messagesLessWidth
                            }

                            onCheckedChanged: {
                                appSettings.setMessagesLessWidth(checked)
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
                                currentIndex = function(){switch (appSettings.messagesPadding) {
                                    case "n": return 0
                                    case "s": return 1
                                    case "r": return 2
                                    case "a": return 3
                                    default:
                                        appSettings.setMessagesPadding("n")
                                        return 0
                                }}()
                            }
                            onCurrentItemChanged: {
                                appSettings.setMessagesPadding(function(){switch (currentItem.text) {
                                        case "none (default)": return "n"
                                        case "sent": return "s"
                                        case "received": return "r"
                                        case "all": return "a"
                                    }}())
                            }
                        }

                        ComboBox {
                            label: qsTr("Size")
                            description: qsTr("Specifies profile picture size in a message")
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
                                currentIndex = function(){switch (appSettings.messageSize) {
                                    case "l": return 0
                                    case "L": return 1
                                    case "m": return 2

                                    case "a":
                                    case "s":
                                    case "t":
                                    case "S":
                                    default:
                                        appSettings.setMessageSize("l")
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.setMessageSize(function(){switch (currentItem.text) {
                                    case "large (default)": return "l"
                                    case "extra large": return "L"
                                    case "launcher": return "a"
                                    case "medium": return "m"
                                    case "small": return "s"
                                    case "small plus": return "t"
                                    case "extra small": return "S"
                                }}())
                            }
                        }

                        TextSwitch {
                            text: qsTr("Align sent messages text to right")
                            enabled: sentMessagesBox.currentIndex != 2
                            description: sentMessagesBox.currentIndex != 2 ? ""
                                           : qsTr("Set Sent messages to reversed or align right to enable.")

                            onCheckedChanged: {
                                appSettings.setAlignMessagesText(checked)
                            }

                            Component.onCompleted: {
                                checked = appSettings.alignMessagesText;
                            }
                        }

                        TextSwitch {
                            text: qsTr("One author text and picture for multiple messages from the same author")
                            onCheckedChanged: {
                                appSettings.setOneAuthor(checked)
                            }

                            Component.onCompleted: {
                                checked = appSettings.oneAuthor;
                            }
                        }

                        /*TextSwitch {
                            text: qsTr("Enable extra padding for new messages from the same author")
                            visible: appSettings.oneAuthor
                            onCheckedChanged: {
                                appSettings.setOneAuthorPadding(checked)
                            }

                            Component.onCompleted: {
                                checked = appSettings.oneAuthorPadding;
                            }
                        }*/

                        ComboBox {
                            label: qsTr("Extra padding")
                            menu: ContextMenu {
                                MenuItem { text: qsTr("no (default)") }
                                MenuItem { text: qsTr("small") }
                                MenuItem { text: qsTr("as pfp") }
                            }
                            visible: appSettings.oneAuthor
                            description: qsTr("Set extra padding for new messages from the same author")

                            Component.onCompleted: {
                                currentIndex = function(){switch (appSettings.oneAuthorPadding) {
                                    case "n": return 0
                                    case "s": return 1
                                    case "p": return 2
                                    default:
                                        console.log("padding "+appSettings.oneAuthorPadding)
                                        appSettings.setOneAuthorPadding("n")
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.setOneAuthorPadding(function(){switch (currentItem.text) {
                                    case "no (default)": return "n"
                                    case "small": return "s"
                                    case "as pfp": return "p"
                                }}())
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
