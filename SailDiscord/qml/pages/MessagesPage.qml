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
        if (!isDemo) python.sendMessage(sendField.text)
        else msgModel.appendDemo(true, sendField.text)
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
                        hintText: qsTr("Say hi ;)")
                    }

                    function getVisibleIndexRange() { // this one actually works!
                        var center_x = messagesList.x + messagesList.width / 2
                        return [indexAt( center_x, messagesList.y + messagesList.contentY + 10),
                                indexAt( center_x, messagesList.y + messagesList.contentY + messagesList.height - 10)]
                    }

                    function checkForUpdate() {
                        var rng = getVisibleIndexRange()
                        for (var i=rng[1]; i<=rng[0]; i++) {
                            if (i>0 && i%27 == 0) {
                                if (!msgModel.get(i)._wasUpdated) {
                                    msgModel.get(i)._wasUpdated = true
                                    python.requestOlderHistory(msgModel.get(msgModel.count-1).messageId)
                                }
                            }
                        }
                    }

                    onContentYChanged: checkForUpdate()

                    delegate: Loader {
                        width: parent.width
                        sourceComponent:
                            switch (type) {
                            case 'join': return joinedItem
                            case '': return defaultItem
                            case 'unknown': return appSettings.defaultUnknownMessages ? defaultItem : unknownItem
                            }

                        Component {
                            id: defaultItem
                            MessageItem {
                                authorid: userid
                                contents: _contents
                                author: _author
                                pfp: _pfp
                                sent: _sent
                                date: _date
                                sameAuthorAsBefore: index == msgModel.count-1 ? false : (msgModel.get(index+1)._author == _author)
                                masterWidth: sameAuthorAsBefore ? msgModel.get(index+1)._masterWidth : -1
                                masterDate: index == msgModel.count-1 ? new Date(1) : msgModel.get(index+1)._date
                                attachments: _attachments

                                function updateMasterWidth() {
                                    msgModel.setProperty(index, "_masterWidth", masterWidth == -1 ? innerWidth : masterWidth)
                                }

                                Component.onCompleted: {
                                    updateMasterWidth()
                                }
                                onMasterWidthChanged: updateMasterWidth()
                                onInnerWidthChanged: updateMasterWidth()
                            }
                        }

                        Component {
                            id: joinedItem
                            Label {
                                textFormat: "RichText"
                                text: qsTr("%1 joined the server").arg('<font color="'+Theme.highlightColor+'">'+_author+'</font>')
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.secondaryHighlightColor
                                width: parent.width
                                wrapMode: Text.Wrap
                            }
                        }

                        Component {
                            id: unknownItem
                            Label {
                                textFormat: "RichText"
                                text: qsTr("Unknown message type: %1").arg('<font color="'+Theme.highlightColor+'">'+APIType+'</font>')
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.secondaryHighlightColor
                                width: parent.width
                                wrapMode: Text.Wrap
                            }
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

        function appendDemo(isyou, thecontents) {
            insert(0, {
               messageId: "-1", _author: isyou ? "you" : "notyou", _contents: thecontents,
               _pfp: isyou ? "https://cdn.discordapp.com/embed/avatars/0.png" : "https://cdn.discordapp.com/embed/avatars/1.png",
               _sent: isyou, _masterWidth: -1, _date: new Date(), _from_history: true, _wasUpdated: false
           })
        }

        function generateDemo() {
            var repeatString = function(string, count) {
                var result = "";
                for (var i = 0; i < count; i++) result += string;
                return result;
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

        function constructCallback(type) {
            return function(_serverid, _channelid, _id, _date, userid, _sent, _author, _icon, history, attachments) {
                if ((_serverid != guildid) || (_channelid != channelid)) return
                var data = {type: type, messageId: _id, _author: _author, _pfp: _icon,
                    _sent: _sent, _masterWidth: -1, _date: new Date(_date), _from_history: history,
                    _wasUpdated: false, userid: userid, _attachments: attachments,
                    _contents: '', APIType: '' } // default

                if (type === '' || type === 'unknown') {
                    data._contents = arguments[10]
                    data._replyid = arguments[11]
                }
                if (type === 'unknown') data.APIType = arguments[12]
                if (history) append(data); else insert(0, data)
            }
        }

        Component.onCompleted: {
            if (isDemo) {
                generateDemo()
                return
            }

            python.setHandler("message", constructCallback(''))
            python.setHandler("newmember", constructCallback('join'))
            python.setHandler("uknownmessage", constructCallback('unknown'))
        }

        onCountChanged: messagesList.forceLayout()
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
        // we unset handler so app won't crash on appending items to destroyed list because resetCurrentChannel is not instant
        python.setHandler("message", function() {}) // undefined is not used for messages not to be logged
        python.setHandler("join", function() {})
        python.setHandler("uknownmessage", function() {})
        python.resetCurrentChannel()
    }
}
