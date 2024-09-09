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

    Timer {
        id: scrollToBottomTimer
        interval: 0
        property int hasRun: 0
        onTriggered: {
            if (!messagesList.quickScrollAnimating){//(hasRun <= 15) {
                //hasRun++
                messagesList.scrollToBottom()
            }

        }
    }

    SilicaListView {
        id: messagesList
        anchors.fill: parent
        model: msgModel

        header: PageHeader {
            id: header
            title: "#"+name
        }

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
            sameAuthorAsBefore: (msgModel.get(index-1) == undefined) ? false : // If this is the first message, false
                                    msgModel.get(index-1)._author == _author
            masterWidth: sameAuthorAsBefore ? msgModel.get(index-1)._masterWidth : -1

            function updateMasterWidth() {
                msgModel.setProperty(index, "_masterWidth", masterWidth == -1 ? innerWidth : masterWidth)
            }

            Component.onCompleted: {
                updateMasterWidth()
                if (!scrollToBottomTimer.running) scrollToBottomTimer.start()
            }
            onMasterWidthChanged: updateMasterWidth()
            onInnerWidthChanged: updateMasterWidth()
        }
    }

    ListModel {
        id: msgModel

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
                           _sent: isyou, _masterWidth: -1, _date: new Date(), _from_history: true
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
                var data = {messageId: _id, _author: _author, _contents: _contents, _pfp: _icon, _sent: _sent, _masterWidth: -1, _date: _date, _from_history: history}
                if (history) insert(0, data); else append(data);
            })
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
    }

    Component.onDestruction: {
        if (isDemo) return
        python.resetCurrentChannel()
    }
}
