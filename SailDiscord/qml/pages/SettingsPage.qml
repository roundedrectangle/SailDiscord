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
                ExpandingSection {
                    id: section

                    //property int sectionIndex: model.index
                    title: qsTr("Behaviour")

                    content.sourceComponent: Column {
                        width: section.width
                        spacing: Theme.paddingSmall

                        SectionHeader { text: qsTr("Servers list") }

                        TextSwitch {
                            text: qsTr("Keep empty space in servers without icons")
                            onCheckedChanged: appSettings.emptySpace = checked
                            Component.onCompleted: checked = appSettings.emptySpace
                        }

                        SectionHeader { text: qsTr("Channels list") }

                        TextSwitch {
                            text: qsTr("Ignore private setting for channels and channel categories")
                            onCheckedChanged: appSettings.ignorePrivate = checked
                            Component.onCompleted: checked = appSettings.ignorePrivate
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
                                        appSettings.sentBehaviour = "r"
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.sentBehaviour = function(){switch (currentItem.text) {
                                    default: case "reversed (default)": return "r"
                                    case "align right": return "a"
                                    case "nothing": return "n"
                                }}()
                            }
                        }

                        TextSwitch {
                            text: qsTr("Less maximum width")
                            enabled: sentMessagesBox.currentIndex != 2
                            description: sentMessagesBox.currentIndex != 2 ?
                                             qsTr("Adds a padding to the left side of a sent message.")
                                           : qsTr("Set Sent messages to reversed or align right to enable.")

                            Component.onCompleted: checked = appSettings.messagesLessWidth
                            onCheckedChanged: appSettings.messagesLessWidth = checked
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
                                        appSettings.messagesPadding = "n"
                                        return 0
                                }}()
                            }
                            onCurrentItemChanged: {
                                appSettings.messagesPadding = function(){switch (currentItem.text) {
                                        default: case "none (default)": return "n"
                                        case "sent": return "s"
                                        case "received": return "r"
                                        case "all": return "a"
                                    }}()
                            }
                        }

                        TextSwitch {
                            text: qsTr("Align sent messages text to right")
                            enabled: sentMessagesBox.currentIndex != 2
                            description: sentMessagesBox.currentIndex != 2 ? ""
                                           : qsTr("Set Sent messages to reversed or align right to enable.")

                            onCheckedChanged: appSettings.alignMessagesText = checked
                            Component.onCompleted: checked = appSettings.alignMessagesText
                        }

                        /*SettingsComboBox {
                            _values: {"author & time (default)": "d", "author": "a", "none": "n"}
                            _title: "Message grouping"
                            _option: appSettings.messageGrouping
                        }*/

                        ComboBox {
                            property var values: ["d", "a", "n"]
                            label: qsTr("Message grouping")
                            currentIndex: values.indexOf(appSettings.messageGrouping) == -1 ? 0 : values.indexOf(appSettings.messageGrouping)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("author & time (default)") }
                                MenuItem { text: qsTr("author") }
                                MenuItem { text: qsTr("none") }
                            }

                            onCurrentItemChanged: appSettings.messageGrouping = values[currentIndex]
                        }

                        /*TextSwitch {
                            text: qsTr("One author text and picture for multiple messages from the same author")
                            onCheckedChanged: appSettings.oneAuthor = checked
                            Component.onCompleted: checked = appSettings.oneAuthor
                        }*/

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
                                        appSettings.oneAuthorPadding = "n"
                                        return 0
                                }}()
                            }

                            onCurrentItemChanged: {
                                appSettings.oneAuthorPadding = function(){switch (currentItem.text) {
                                    default: case "no (default)": return "n"
                                    case "small": return "s"
                                    case "as pfp": return "p"
                                }}()
                            }
                        }


                        ButtonLayout {
                            Button {
                                text: qsTr("Preview")
                                onClicked: pageStack.push(Qt.resolvedUrl("MessagesPage.qml"), { isDemo: true })
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Item {width: 1; height: Theme.paddingLarge}
                    }
                }

                ExpandingSection {
                    id: sessionSection

                    //property int sectionIndex: model.index
                    title: qsTr("Session")

                    content.sourceComponent: Column {
                        width: sessionSection.width
                        spacing: Theme.paddingSmall

                        Column {
                            width: parent.width
                            spacing: Theme.paddingLarge
                            ButtonLayout {
                                Button {
                                    text: qsTr("Log out")
                                    onClicked: appConfiguration.token = ""
                                }

                                Button {
                                    text: qsTr("Clear cache")
                                    onClicked: python.clearCache()
                                }
                            }

                            ButtonLayout {
                                Button {
                                    text: qsTr("Reset all settings")
                                    onClicked: {
                                        appSettings.clear()
                                        pageStack.push(settingsResetPage)
                                    }
                                }
                            }
                        }

                        Slider {
                            value: appSettings.cachePeriod
                            minimumValue: 0
                            maximumValue: 7
                            stepSize: 1
                            width: parent.width
                            valueText: switch (value) {
                               default: case 0: return qsTr("Never")
                               case 1: return qsTr("On app restart")
                               case 2: return qsTr("Hourly")
                               case 3: return qsTr("Daily")
                               case 4: return qsTr("Weekly")
                               case 5: return qsTr("Monthly")
                               case 6: return qsTr("Half-yearly")
                               case 7: return qsTr("Yearly")
                            }

                            label: "Cache update period"

                            onValueChanged: appSettings.cachePeriod = value
                        }

                        Label {
                            text: qsTr("Changes how often the cache is updated. App restart might be required")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                            wrapMode: Text.Wrap
                            width: parent.width - Theme.horizontalPageMargin
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsResetPage
        Page {
            backNavigation: false
            SilicaFlickable {
                ViewPlaceholder {
                    enabled: true
                    text: qsTr("Settings reset")
                    hintText: qsTr("Please restart the app")
                }
            }
        }
    }
}
