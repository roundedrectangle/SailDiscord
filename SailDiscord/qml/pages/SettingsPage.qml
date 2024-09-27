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
                            property var values: ["r", "a", "n"]
                            label: qsTr("Sent messages")
                            description: qsTr("Sets for which messages extra padding should apply")
                            currentIndex: values.indexOf(appSettings.sentBehaviour) == -1 ? 0 : values.indexOf(appSettings.sentBehaviour)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("reversed (default)") }
                                MenuItem { text: qsTr("align right") }
                                MenuItem { text: qsTr("nothing") }
                            }

                            onCurrentItemChanged: appSettings.sentBehaviour = values[currentIndex]
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
                            property var values: ["n", "s", "r", "a"]
                            label: qsTr("Extra padding")
                            description: qsTr("Sets for which messages extra padding should apply")
                            currentIndex: values.indexOf(appSettings.messagesPadding) == -1 ? 0 : values.indexOf(appSettings.messagesPadding)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("none (default)") }
                                MenuItem { text: qsTr("sent") }
                                MenuItem { text: qsTr("received") }
                                MenuItem { text: qsTr("all") }
                            }

                            onCurrentItemChanged: appSettings.messagesPadding = values[currentIndex]
                        }

                        TextSwitch {
                            text: qsTr("Align sent messages text to right")
                            enabled: sentMessagesBox.currentIndex != 2
                            description: sentMessagesBox.currentIndex != 2 ? ""
                                           : qsTr("Set Sent messages to reversed or align right to enable.")

                            onCheckedChanged: appSettings.alignMessagesText = checked
                            Component.onCompleted: checked = appSettings.alignMessagesText
                        }

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

                        ComboBox {
                            label: qsTr("Extra padding")
                            visible: appSettings.messageGrouping !== "n"
                            description: qsTr("Set extra padding for new messages from the same author")

                            property var values: ["n", "s", "p"]
                            currentIndex: values.indexOf(appSettings.oneAuthorPadding) == -1 ? 0 : values.indexOf(appSettings.oneAuthorPadding)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("no (default)") }
                                MenuItem { text: qsTr("small") }
                                MenuItem { text: qsTr("as pfp") }
                            }
                            onCurrentItemChanged: appSettings.oneAuthorPadding = values[currentIndex]
                        }

                        ButtonLayout {
                            Button {
                                text: qsTr("Preview")
                                onClicked: pageStack.push(Qt.resolvedUrl("MessagesPage.qml"), { isDemo: true })
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Item {width: 1; height: Theme.paddingLarge}

                        SectionHeader { text: qsTr("Message field") }

                        TextSwitch {
                            text: qsTr("Send messages by enter")
                            checked: appSettings.sendByEnter
                            onCheckedChanged: appSettings.sendByEnter = checked
                        }

                        TextSwitch {
                            text: qsTr("Focus input message area after send")
                            checked: appSettings.focusAfterSend
                            onCheckedChanged: appSettings.focusAfterSend = checked
                        }

                        TextSwitch {
                            text: qsTr("Focus input message area on channel open")
                            checked: appSettings.focudOnChatOpen
                            onCheckedChanged: appSettings.focudOnChatOpen = checked
                        }
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
                                    text: qsTr("Reset tutorial")
                                    onClicked: appConfiguration.usernameTutorialCompleted = false
                                }
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
