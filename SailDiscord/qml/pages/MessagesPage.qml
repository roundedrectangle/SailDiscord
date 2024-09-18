import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string guildid
    property string channelid
    property string name
    property bool isDemo: false
    property bool sendPermissions: true

    Timer {
        id: activeFocusTimer
        interval: 100
        onTriggered: sendField.forceActiveFocus()
    }

    function sendMessage() {
        python.sendMessage(sendField.text)
        sendField.text = ""
        if (appSettings.focusAfterSend) activeFocusTimer.start()
    }

    SilicaFlickable {
        anchors.fill: parent

        Column {
            width: parent.width
            height: parent.height

            PageHeader {
                id: header
                title: "#"+name
            }

            Item {
                width: parent.width
                height: parent.height - header.height - (sendField.visible ? sendField.height : 0)

                SilicaListView {
                    id: messagesList
                    anchors.fill: parent
                    model: msgModel
                    clip: true
                    verticalLayoutDirection: ListView.BottomToTop

                    ViewPlaceholder {
                        enabled: msgModel.count === 0
                        text: qsTr("No messages")
                        hintText: qsTr("Say hi (Coming soon)")
                    }

                    delegate: MessageItem {
                        contents: _contents
                        author: _author
                        pfp: _pfp
                        sent: _sent
                        date: _date
                        sameAuthorAsBefore: index == msgModel.count-1 ? false : (msgModel.get(index+1)._author == _author)
                        masterWidth: sameAuthorAsBefore ? msgModel.get(index+1)._masterWidth : -1
                        masterDate: index == msgModel.count-1 ? new Date(1) : msgModel.get(index+1)._date

                        property int yoff: Math.round(y - messagesList.contentY)
                        //property bool isFullyVisible: (yoff > messagesList.y && yoff + height < messagesList.y + messagesList.height)
                        property bool isFullyVisible: (yoff > messagesList.y && yoff < messagesList.y + messagesList.height)
                        property bool newMessagesRequired: (isFullyVisible) //&& initializationComplete
                        property bool initializationComplete: false

                        Timer {
                            interval: 1000
                            onTriggered: parent.initializationComplete = true
                        }

                        function updateMasterWidth() {
                            msgModel.setProperty(index, "_masterWidth", masterWidth == -1 ? innerWidth : masterWidth)
                        }

                        Component.onCompleted: {
                            updateMasterWidth()
                            _wasRecreated = function(){switch (_wasRecreated) {
                                case -1: return 0
                                case 0: return 1
                                case 1: default: return 2
                            }}() // might be removed!

                            //if (_wasRecreated === 1) shared.log(_contents)
                        }
                        onMasterWidthChanged: updateMasterWidth()
                        onInnerWidthChanged: updateMasterWidth()

                        onIsFullyVisibleChanged: {
                            //if (isFullyVisible) shared.log("NEW MESSAGES ARE NEEDED!!!1!!!!!!!1!1!", index, _contents)
                            //python.requestOlderHistory(channelid, messageId)
                        }
                    }
                }
            }

            Row {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                visible: sendPermissions

                TextArea {
                    id: sendField
                    width: parent.width - sendButton.width

                    placeholderText: qsTr("Type something")
                    hideLabelOnEmptyField: false
                    labelVisible: false
                    anchors.verticalCenter: parent.verticalCenter
                    backgroundStyle: TextEditor.UnderlineBackground
                    horizontalAlignment: TextEdit.AlignLeft

                    EnterKey.iconSource: appSettings.sendByEnter ? "image://theme/icon-m-enter-accept" : ""
                    EnterKey.onClicked: if (appSettings.sendByEnter) sendMessage()
                }

                IconButton {
                    id: sendButton
                    width: Theme.iconSizeMedium + 2 * Theme.paddingSmall
                    height: width
                    enabled: sendField.text.length !== 0
                    anchors.bottom: parent.bottom
                    icon.source: "image://theme/icon-m-send"

                    onClicked: sendMessage()
                }
            }
        }
    }

    ListModel {
        id: msgModel

        property int updateCounter: 0

        function generateDemo() {
            var repeatString = function(string, count) {
                var result = "";
                for (var i = 0; i < count; i++) result += string;
                return result;
            };

            var appendDemo = function(isyou, thecontents) {
                append({
                           messageId: "-1", _author: isyou ? "you" : "notyou", _contents: thecontents,
                           _pfp: isyou ? "https://cdn.discordapp.com/embed/avatars/0.png" : "https://cdn.discordapp.com/embed/avatars/1.png",
                           _sent: isyou, _masterWidth: -1, _date: new Date(), _from_history: true, _wasRecreated: -1
                       })
            }

            // Append demo messages

            appendDemo(true, "First message!")
            appendDemo(true, "Second message")
            appendDemo(true, "A l "+repeatString("o ", 100)+"ng message.")

            appendDemo(false, "First message!")
            appendDemo(false, "Second message")
            appendDemo(false, "A l "+repeatString("o ", 100)+"ng message.")

            appendDemo(true, repeatString("Hello, world. ", 50))
            appendDemo(true, "Second message")
            appendDemo(true, "A l "+repeatString("o ", 100)+"ng message.")

            appendDemo(false, repeatString("Hello, world. ", 50))
            appendDemo(false, "Second message")
            appendDemo(false, "A l "+repeatString("o ", 100)+"ng message.")
        }

        Component.onCompleted: {
            if (isDemo) {
                generateDemo()
                return
            }

            python.setHandler("message", function (_serverid, _channelid, _id, _author, _contents, _icon, _sent, _date, history) {
                if ((_serverid != guildid) || (_channelid != channelid)) return;
                var data = {messageId: _id, _author: _author, _contents: _contents, _pfp: _icon,
                    _sent: _sent, _masterWidth: -1, _date: new Date(_date), _from_history: history,
                    _wasRecreated: -1}
                if (!history) insert(0, data); else append(data);
            })
        }

        onCountChanged: {
            messagesList.forceLayout()
            if (count % 30 == 0) {
                if (updateCounter >= 10) return //todo: fix without this, for now app lags even with this, even when done
                console.log("New 30th message! History update is required!")
                python.requestOlderHistory(channelid, get(count-1).messageId)
                updateCounter++
            }
        }
    }

    Component.onCompleted: {
        if (isDemo) {
            name = "demo-channel"
            guildid = -5
            channelid = -5
            return
        }

        python.setCurrentChannel(guildid, channelid)
        if (appSettings.focudOnChatOpen) activeFocusTimer.start()
    }

    Component.onDestruction: {
        if (isDemo) return
        python.resetCurrentChannel()
    }
}
