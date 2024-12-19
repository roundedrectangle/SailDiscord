import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    property alias sections: secGroup

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
                id: secGroup
                ExpandingSection {
                    id: section
                    title: qsTr("Behaviour")

                    content.sourceComponent: Column {
                        width: section.width
                        spacing: Theme.paddingSmall

                        SectionHeader { text: qsTr("Channels list") }

                        TextSwitch {
                            text: qsTr("Show private channels")
                            onCheckedChanged: appSettings.ignorePrivate = checked
                            Component.onCompleted: checked = appSettings.ignorePrivate
                        }

                        SectionHeader { text: qsTr("Messages") }

                        TextSwitch {
                            text: qsTr("Use default type on unknown types")
                            checked: appSettings.defaultUnknownMessages
                            onCheckedChanged: appSettings.defaultUnknownMessages = checked
                        }

                        SectionHeader { text: qsTr("Replies") }
                        Label {
                            width: parent.width - 2*x
                            x: Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            text: qsTr("The only supported reply types at the moment are replied and forwarded messages")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                            bottomPadding: Theme.paddingMedium
                        }

                        /*TextSwitch {
                            text: qsTr("Use default type on unknown types")
                            checked: appSettings.defaultUnknownReferences
                            onCheckedChanged: appSettings.defaultUnknownReferences = checked
                        }*/

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
                    id: lookSection
                    title: qsTr("Appearance")

                    content.sourceComponent: Column {
                        width: lookSection.width
                        spacing: Theme.paddingSmall

                        SectionHeader { text: qsTr("Servers list") }

                        TextSwitch {
                            text: qsTr("Keep empty space in servers without icons")
                            onCheckedChanged: appSettings.emptySpace = checked
                            Component.onCompleted: checked = appSettings.emptySpace
                        }


                        SectionHeader { text: qsTr("Messages") }

                        ComboBox {
                            id: sentMessagesBox
                            property var values: ["r", "n"]
                            label: qsTr("Sent messages")
                            description: qsTr("Sets for which messages extra padding should apply")
                            currentIndex: values.indexOf(appSettings.sentBehaviour) == -1 ? 0 : values.indexOf(appSettings.sentBehaviour)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("reversed (default)") }
                                MenuItem { text: qsTr("nothing") }
                            }

                            onCurrentItemChanged: appSettings.sentBehaviour = values[currentIndex]
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

                            property var values: ["p", "s", "n"]
                            currentIndex: values.indexOf(appSettings.oneAuthorPadding) == -1 ? 0 : values.indexOf(appSettings.oneAuthorPadding)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("as pfp (default)") }
                                MenuItem { text: qsTr("small") }
                                MenuItem { text: qsTr("no") }
                            }
                            onCurrentItemChanged: appSettings.oneAuthorPadding = values[currentIndex]
                        }

                        TextSwitch {
                            text: qsTr("High-contrast mode")
                            onCheckedChanged: appSettings.highContrastMessages = checked
                            Component.onCompleted: checked = appSettings.highContrastMessages
                        }

                        TextSwitch {
                            text: qsTr("Use Twemoji instead of default Emoji")
                            checked: appSettings.twemoji
                            onCheckedChanged: appSettings.twemoji = checked
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
                                    onClicked: Remorse.popupAction(settingsPage, qsTr("Logged out"), function(){ appConfiguration.token = "" })
                                }
                                Button {
                                    text: qsTr("Clear cache")
                                    onClicked: Remorse.popupAction(settingsPage, qsTr("Cleared cache"), function(){ python.clearCache() })
                                }
                            }

                            ButtonLayout {
                                /*Button {
                                    text: qsTr("Reset tutorial")
                                    onClicked: appConfiguration.usernameTutorialCompleted = false
                                }*/
                                Button {
                                    text: qsTr("Reset all settings")
                                    onClicked: Remorse.popupAction(settingsPage, qsTranslate("SettingsPage", "Settings reset", "Past tense"), function() {
                                        appSettings.clear()
                                        pageStack.push(settingsResetPage)
                                    })
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
                            width: parent.width - 2*x
                            x: Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            text: qsTr("Changes how often the cache is updated. App restart might be required")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                            bottomPadding: Theme.paddingMedium
                        }
                    }
                }

                ExpandingSection {
                    id: advancedSection
                    title: qsTr("Advanced")
                    content.sourceComponent: Column {
                        width: lookSection.width
                        spacing: Theme.paddingSmall

                        SectionHeader { text: qsTr("Networking") }
                        Label {
                            width: parent.width - 2*x
                            x: Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            text: qsTr("Login page always uses the global proxy regardless of these settings. Attachments, avatars and other static elements may not use proxy at all. Restart the app to apply")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                            bottomPadding: Theme.paddingMedium
                        }
                        ComboBox {
                            id: proxyTypeBox
                            property var values: ["g", "n", "c"]
                            label: qsTr("Proxy")
                            currentIndex: values.indexOf(appSettings.proxyType) == -1 ? 0 : values.indexOf(appSettings.proxyType)
                            menu: ContextMenu {
                                MenuItem { text: qsTr("global proxy") }
                                MenuItem { text: qsTr("disable") }
                                MenuItem { text: qsTr("custom") }
                            }

                           onCurrentItemChanged: appSettings.proxyType = values[currentIndex]
                        }
                        TextField {
                            enabled: proxyTypeBox.values[proxyTypeBox.currentIndex] == "c"
                            label: qsTr("HTTP proxy address")
                            description: qsTr("Specify port by semicolon, if required")
                            text: appSettings.customProxy
                            onTextChanged: appSettings.customProxy = text
                        }

                        SectionHeader { text: qsTr("Debugging") }
                        TextSwitch {
                            text: qsTr("Show info messages in notifications")
                            checked: appSettings.infoInNotifications
                            onCheckedChanged: appSettings.infoInNotifications = checked
                        }
                        TextSwitch {
                            text: qsTr("Display unformatted HTML text in messages")
                            description: qsTr("Text will still be parsed through Showdown, but HTML tags will be displayed as-is")
                            checked: appSettings.unformattedText
                            onCheckedChanged: appSettings.unformattedText = checked
                        }

                        SectionHeader { text: qsTr("Experimental") }
                        IconComboBox {
                            label: qsTr("Overview mode")
                            description: currentIndex == 1 ? qsTr("Tries to mimic the UI in real Discord") : qsTr("Classic UI with tabs")
                            icon.source: "image://theme/icon-m-ambience"
                            currentIndex: appSettings.modernUI ? 1 : 0
                            menu: ContextMenu {
                                MenuItem { text: qsTr("Classic") }
                                MenuItem { text: qsTr("Modern") }
                            }

                           onCurrentItemChanged: appSettings.modernUI = currentIndex == 1
                        }
                        IconTextSwitch {
                            icon.source: "image://theme/icon-m-developer-mode"
                            text: qsTr("Developer mode")
                            description: qsTr("Enables certain features useful for developers such as copying IDs")
                            checked: appSettings.developerMode
                            onCheckedChanged: appSettings.developerMode = checked
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
                anchors.fill: parent
                ViewPlaceholder {
                    enabled: true
                    text: qsTranslate("SettingsPage", "Settings reset", "Past tense")
                    hintText: qsTr("Please restart the app")
                }
            }
        }
    }
}
