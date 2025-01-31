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
    property bool managePermissions: false
    property bool isDM: false
    property bool isGroup: false
    property string userid: ''
    property string usericon: ''
    property string topic

    property string previouslyEnteredText: ''
    property int currentFieldAction: 0 // 0: none, 1: editing, 2: replying
    property string actionID: '-1' // editing or replying message ID
    property string actionInfo: '' // replying contents
    property bool _loaded: false

    Timer {
        id: activeFocusTimer
        interval: 100
        onTriggered: sendField.forceActiveFocus()
    }

    function sendMessage() {
        if (!isDemo) py.sendMessage(sendField.text)
        else msgModel.appendDemo(true, sendField.text)
        sendField.text = previouslyEnteredText
        previouslyEnteredText = ''
        currentFieldAction = 0
        if (appSettings.focusAfterSend) activeFocusTimer.start()
    }

    function applyEdit() {
        if (isDemo) return
        py.call2('edit_message', [actionID, sendField.text])
        var i = msgModel.findIndexById(actionID)
        if (i >= 0) {
            i = msgModel.get(i)
            i.contents = sendField.text
            i.formatted = shared.markdown(sendField.text, true)
            i._flags.edit = true
        }

        sendField.text = previouslyEnteredText
        previouslyEnteredText = ''
        actionID = '-1'
        currentFieldAction = 0
        if (appSettings.focusAfterSend) activeFocusTimer.start()
    }

    function applyReply() {
        if (!isDemo) py.call2('reply_to', [actionID, sendField.text])
        else msgModel.appendDemo(true, sendField.text)
        sendField.text = previouslyEnteredText
        previouslyEnteredText = ''
        currentFieldAction = 0
        if (appSettings.focusAfterSend) activeFocusTimer.start()
    }

    function loadAboutDM() { pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { userid: userid, name: name, icon: usericon }) }

    /*DockedPanel {
        id: topicPanel
        width: isPortrait ? parent.width : Math.min(Screen.width, Screen.height)
        height: isPortrait ? topicDrawerLabel.height + Theme.paddingLarge : parent.height
        dock: isPortrait ? Dock.Top : Dock.Right

        function toggle() {
            if (open) hide()
            else show()
        }

        Label {
            id: topicDrawerLabel
            text: topic
            x: isPortraint ? Theme.horizontalPageMargin : Theme.paddingLarge
            width: parent.width - 2*x
            height: implicitHeight + 2*Theme.paddingLarge
            textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }

        MouseArea  {
            anchors.fill: parent
            onClicked: parent.hide()
        }
    }*/

    Drawer {
        id: topicPanel
        anchors.fill: parent
        dock: isPortrait ? Dock.Top : Dock.Right
        backgroundSize: isPortrait ? Math.min(topicDrawerLabel.height, height/2) : (width / 2)

        background: SilicaFlickable {
            contentHeight: topicDrawerLabel.height
            anchors.fill: parent
            Label {
                id: topicDrawerLabel
                text: topic
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: implicitHeight + 2*Theme.paddingLarge
                textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: height

            BusyLabel {
                running: msgModel.count === 0 && waitForMessagesTimer.wait
            }

            ViewPlaceholder {
                enabled: msgModel.count === 0 && !waitForMessagesTimer.wait
                text: qsTr("No messages")
                hintText: sendPermissions ? qsTr("Say hi ;)") : qsTr("Wait for someone to post something")

                Timer {
                    id: waitForMessagesTimer
                    interval: 2500
                    running: started
                    property bool started: false
                    property bool wait: !started || running
                }
            }

            PageHeader {
                id: header
                title: (isGroup ? '' : (isDM ? '@' : "#"))+name
                _titleItem.textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                interactive: isDM
                titleColor: highlighted ? palette.primaryColor : palette.highlightColor
                Component.onCompleted: if (isDM) _navigateForwardMouseArea.clicked.connect(loadAboutDM)

                Label {
                    parent: header.extraContent
                    text: topic
                    visible: !!text
                    anchors.centerIn: parent
                    textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    color: Theme.secondaryHighlightColor

                    MouseArea {
                        id: openTopicMouseArea
                        anchors.fill: parent
                        enabled: parent.visible && parent.implicitWidth > header.extraContent.width
                        onClicked: if (enabled) topicPanel.show()
                    }
                }
            }

            SilicaListView {
                id: messagesList
                anchors {
                    top: header.bottom
                    bottom: sendBox.visible ? sendBox.top : parent.bottom
                }
                width: parent.width
                model: msgModel
                clip: true
                verticalLayoutDirection: ListView.BottomToTop

                VerticalScrollDecorator {}

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
                                py.requestOlderHistory(msgModel.get(msgModel.count-1).messageId)
                            }
                        }
                    }
                }

                onContentYChanged: checkForUpdate()

                delegate: Loader {
                    width: parent.width
                    sourceComponent:
                        switch (type) {
                        case '': return defaultItem
                        case 'unknown': return appSettings.defaultUnknownMessages ? defaultItem : systemItem
                        default: return systemItem
                        }

                    Rectangle {
                        anchors.fill: parent
                        visible: appSettings.highContrastMessages && parent.status == Loader.Ready
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0) }
                            GradientStop { position: 1.0; color: Theme.rgba(Theme.secondaryColor, 0.1) }
                        }
                    }

                    Component {
                        id: defaultItem
                        MessageItem {
                            authorid: userid
                            contents: model.contents
                            formattedContents: model.formatted
                            author: _author
                            pfp: _pfp
                            sent: _sent
                            date: _date
                            sameAuthorAsBefore: index == msgModel.count-1 ? false : (msgModel.get(index+1)._author == _author)
                            masterWidth: sameAuthorAsBefore ? msgModel.get(index+1)._masterWidth : -1
                            masterDate: index == msgModel.count-1 ? new Date(1) : msgModel.get(index+1)._date
                            attachments: _attachments
                            reference: _ref
                            flags: _flags
                            msgid: messageId
                            jumpUrl: model.jumpUrl
                            sendPermissions: page.sendPermissions
                            managePermissions: page.managePermissions
                            showRequestableOptions: !isDemo
                            highlightStarted: model.highlightStarted
                            onHighlightStartedChanged: model.highlightStarted = highlightStarted
                            jumpToReference: function(id) {
                                var i = msgModel.findIndexById(id)
                                if (i >= 0) {
                                    messagesList.positionViewAtIndex(i, ListView.Contain)
                                    msgModel.setProperty(i, 'highlightStarted', true)
                                    msgModel.setProperty(i, 'highlightStarted', false)
                                    return true
                                }
                                return false
                            }

                            function updateMasterWidth() {
                                msgModel.setProperty(index, "_masterWidth", masterWidth == -1 ? innerWidth : masterWidth)
                            }
                            Component.onCompleted: {
                                updateMasterWidth()
                            }
                            onMasterWidthChanged: updateMasterWidth()
                            onInnerWidthChanged: updateMasterWidth()

                            onEditRequested: {
                                previouslyEnteredText = sendField.text
                                sendField.text = model.contents
                                actionID = messageId
                                currentFieldAction = 1
                            }
                            onDeleteRequested: remorseAction(qsTr("Message deleted"), function() { opacity = 0; py.call2('delete_message', [messageId]) })
                            onReplyRequested: {
                                actionID = messageId
                                currentFieldAction = 2
                                actionInfo = model.contents
                            }
                        }
                    }

                    Component {
                        id: systemItem
                        SystemMessageItem { _model: model; label.horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }

            Column {
                id: sendBox
                width: parent.width
                visible: sendPermissions
                anchors.bottom: parent.bottom
                spacing: Theme.paddingLarge

                Item {
                    visible: currentFieldAction > 0
                    width: parent.width - Theme.horizontalPageMargin*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: Math.max(children[0].height, children[1].height)
                    Icon {
                        id: replyActionIcon
                        visible: currentFieldAction == 2
                        anchors.left: parent.left
                        source: "image://theme/icon-m-message-forward"
                    }
                    Label {
                        anchors.left: replyActionIcon.visible ? replyActionIcon.right : parent.left
                        anchors.leftMargin: replyActionIcon.visible ? Theme.paddingLarge : 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: currentFieldAction == 1 ? qsTr("Editing message") : actionInfo
                        font.bold: true
                        color: Theme.highlightColor
                        width: parent.width - (undoActionButton.width + Theme.paddingLarge) - (replyActionIcon.visible ? (replyActionIcon.width + Theme.paddingLarge) : 0)
                        truncationMode: TruncationMode.Fade
                    }
                    IconButton {
                        id: undoActionButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-clear"
                        onClicked: {
                            if (currentFieldAction == 1) sendField.text = previouslyEnteredText
                            if (previouslyEnteredText) activeFocusTimer.start()
                            previouslyEnteredText = ''
                            actionID = '-1'
                            actionInfo = ''
                            currentFieldAction = 0
                        }
                    }
                }

                Row {
                    width: parent.width
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
                        visible: !appSettings.sendByEnter
                        width: visible ? (Theme.iconSizeMedium + 2 * Theme.paddingSmall) : 0
                        height: width
                        enabled: sendField.text.length !== 0
                        anchors.bottom: parent.bottom
                        icon.source: "image://theme/icon-m-" + (currentFieldAction == 1 ? "accept" : "send")

                        onClicked: switch (currentFieldAction) {
                                   case 0: sendMessage();break
                                   case 1: applyEdit();break
                                   case 2: applyReply()
                                   }
                    }
                }
            }

            PushUpMenu {
                visible: isDM
                MenuItem {
                    text: qsTranslate("AboutUser", "About", "User")
                    onClicked: loadAboutDM()
                }
            }

            MouseArea {
                enabled: topicPanel.open
                anchors.fill: parent
                onClicked: topicPanel.hide()
            }
        }
    }

    ListModel {
        id: msgModel

        property int updateCounter: 0

        function combineObjects(obj1, obj2) {
            var res = obj1
            for (var attrname in obj2) {
                if (res[attrname] !== undefined && (typeof obj2[attrname] === 'object') && (typeof res[attrname] === 'object'))
                    res[attrname] = combineObjects(res[attrname], obj2[attrname])
                else res[attrname] = obj2[attrname]
            }
            return res
        }

        function appendDemo2(toAppend) {
            insert(0, combineObjects({type: '', messageId: '-1', userid: '-1',
                                      _from_history: true, _wasUpdated: false,
                                      _masterWidth: -1, _date: new Date(),
                                      _flags: {edit: false, bot: false, nickAvailable: false,
                                          system: false, color: undefined},
                                      _sent: false, contents: "", formatted: "",
                                      _author: "unknown", _pfp: '',
                                      _ref: {}, _attachments: [],
                                  }, toAppend))
        }

        function appendDemo(isyou, thecontents, additionalOptions) {
            additionalOptions = additionalOptions !== undefined ? additionalOptions : {}
            appendDemo2(combineObjects(
                            {_sent: isyou, contents: thecontents, formatted: shared.markdown(thecontents, undefined, additionalOptions._flags ? additionalOptions._flags.edit : false), _author: isyou ? "you" : "notyou", _pfp: "https://cdn.discordapp.com/embed/avatars/"+(isyou ? "0" : "1")+".png"},
                            additionalOptions))
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

            appendDemo(false, "Some long messages...")


            // TODO: attachments and replies
            //appendDemo(true, "Hey everyone, look at this pic!", {_attachments: [{}]})

            appendDemo(true, "# Markdown showcase:\n*Italic*, **bold**, ***both***, `code`, normal")
            appendDemo2({contents: "I am a normal guy, just have a colored nickname", formatted: "I am a normal guy, just have a colored nickname", _author: "normal_guy", _pfp: "https://cdn.discordapp.com/embed/avatars/4.png", _flags: {color:"green"}})
            appendDemo2({contents: "I am a system guy", formatted: "I am a system guy", _pfp: "https://cdn.discordapp.com/embed/avatars/3.png", _flags: {system:true}})
            appendDemo2({contents: "I am a bot!", formatted: "I am a bot!", _author: "a_bot", _pfp: "https://cdn.discordapp.com/embed/avatars/2.png", _flags: {bot:true}})
            appendDemo(true, "Edited message...", {_flags: {edit: true}})
            appendDemo(true, "First message!")
        }

        function findIndexById(id) {
            for(var i=0; i < count; i++)
                if (get(i).messageId == id) return i
            return -1
        }

        Component.onCompleted: if (isDemo) generateDemo()

        onCountChanged: messagesList.forceLayout()
    }

    function load() {
        if (status != PageStatus.Active || _loaded || isDemo) return
        _loaded = true
        waitForMessagesTimer.started = true

        shared.registerMessageCallbacks(guildid, channelid, function(history, data) {
            if (history) msgModel.append(data); else msgModel.insert(0, data)
        }, function(before, data) {
            var i = msgModel.findIndexById(before)
            if (i >= 0) {
                if (data) msgModel.set(i, data)
                else msgModel.remove(i)
            }
        })

        py.setCurrentChannel(guildid, channelid)
        if (appSettings.focudOnChatOpen && sendPermissions) activeFocusTimer.start()
    }

    Component.onCompleted: {
        if (isDemo) {
            name = "demo-channel"
            guildid = -5
            channelid = -5
            return
        }

        load()
    }

    onStatusChanged: load()

    Component.onDestruction: {
        if (isDemo) return
        shared.cleanupMessageCallbacks()
        py.resetCurrentChannel()
    }
}
