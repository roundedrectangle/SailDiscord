import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string guildid
    property string channelid
    property string name
    property bool isDemo: false

    // Here we should set some stuff for DMs/groups by default:
    property bool sendPermissions: true
    property bool attachPermission: true
    property bool managePermissions: false

    property bool isDM: false
    property bool isGroup: false
    property string userid: ''
    property var usericon
    property string topic

    property string previouslyEnteredText: ''
    property int currentFieldAction: 0 // 0: none, 1: editing, 2: replying
    property string actionID: '-1' // editing or replying message ID
    property string actionInfo: '' // replying contents
    property var attachments: []
    property bool _loaded: false

    signal channelOpenRequested(string id)


    Timer {
        id: activeFocusTimer
        interval: 100
        onTriggered: sendField.forceActiveFocus()
    }

    function doSend() {
        switch (currentFieldAction) {
        case 0:
            if (isDemo) msgModel.appendDemo(true, sendField.text)
            else py.call2('send_message', [sendField.text, attachments])
            attachments = []
            break
        case 1:
            if (!isDemo) py.call2('edit_message', [actionID, sendField.text])

            var i = msgModel.findIndexById(actionID)
            if (i >= 0) {
                i = msgModel.get(i)
                i.contents = sendField.text
                i.formattedContents = shared.markdown(sendField.text, true)
                i.flags.edit = true
            }

            break
        case 2:
            if (isDemo) msgModel.appendDemo(true, sendField.text)
            else py.call2('reply_to', [actionID, sendField.text])
            attachments = []
        }

        actionID = '-1'
        sendField.text = previouslyEnteredText
        previouslyEnteredText = ''
        currentFieldAction = 0
        if (appSettings.focusAfterSend) activeFocusTimer.start()
    }

    function loadAboutDM() { pageStack.push(Qt.resolvedUrl("AboutUserPage.qml"), { userid: userid, name: name, icon: usericon }) }

    function addAttachment(properties, type) {
        attachments.push({
                             path: properties.filePath,
                             name: properties.fileName,
                             mime: properties.mimeType,
                             type: type,
                             spoiler: false,
                             description: '',
                             title: ''
                         })
        attachmentsChanged()
    }

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
                interactive: isDM
                titleColor: highlighted ? palette.primaryColor : palette.highlightColor
                Component.onCompleted: if (isDM) _navigateForwardMouseArea.clicked.connect(loadAboutDM)

                Label {
                    parent: header.extraContent
                    text: topic
                    visible: !!text
                    anchors.centerIn: parent
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
                                py.call2('get_history_messages', msgModel.get(msgModel.count-1).messageId)
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
                            sendPermissions: page.sendPermissions
                            managePermissions: page.managePermissions
                            showRequestableOptions: !isDemo

                            sameAuthorAsBefore: index == msgModel.count-1 ? false : (msgModel.get(index+1).author == author)
                            masterWidth: sameAuthorAsBefore ? msgModel.get(index+1)._masterWidth : -1
                            masterDate: index == msgModel.count-1 ? new Date(1) : msgModel.get(index+1).date

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
                            Component.onCompleted: updateMasterWidth()
                            onMasterWidthChanged: updateMasterWidth()
                            onInnerWidthChanged: updateMasterWidth()

                            onEditRequested: {
                                previouslyEnteredText = sendField.text
                                sendField.text = model.contents
                                actionID = messageId
                                currentFieldAction = 1
                            }
                            onDeleteRequested: remorseAction(qsTr("Message deleted"), function() {
                                opacity = 0
                                py.call2('delete_message', messageId)
                            })
                            onReplyRequested: {
                                actionID = messageId
                                currentFieldAction = 2
                                actionInfo = model.contents
                            }

                            channelLinkClickable: !isDemo && !isDM && !isGroup
                            onChannelOpenRequested: page.channelOpenRequested(id)
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

                Item {
                    visible: currentFieldAction > 0
                    width: parent.width - Theme.horizontalPageMargin*2
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: Theme.paddingLarge
                    }
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

                Flickable {
                    // TODO: add some kind of effect (FadeableFlickable doesn't work that well here)
                    // TODO: add padding to left and right (without breaking context menu)
                    width: parent.width
                    visible: attachments.length > 0 && currentFieldAction != 1
                    height: visible ? attachmentsPreviewRow.height : 0
                    contentWidth: Math.max(width, attachmentsPreviewRow.width)

                    Row {
                        id: attachmentsPreviewRow
                        spacing: Theme.paddingMedium
                        x: Theme.horizontalPageMargin

                        IconButton {
                            width: Theme.itemSizeSmall
                            height: Theme.itemSizeMedium

                            icon.source: "image://theme/icon-m-clear"
                            visible: attachments.length > 0
                            onClicked: attachments = []
                        }

                        Repeater {
                            model: attachments
                            GridItem {
                                id: gridItem
                                width: Theme.itemSizeMedium
                                contentWidth: attachmentPreviewLoader.width //+ Theme.paddingMedium*2
                                contentHeight: attachmentPreviewLoader.height //+ Theme.paddingMedium*2

                                function remove() {
                                    remorseDelete(function() {
                                        attachments.splice(index, 1)
                                        attachmentsChanged()
                                    })
                                }

                                Loader {
                                    id: attachmentPreviewLoader
                                    width: Theme.itemSizeMedium
                                    height: Theme.itemSizeMedium
                                    sourceComponent: switch(modelData.type) {
                                                     case 0:
                                                     case 1:
                                                         return thumbnailComponent
                                                     default:
                                                         iconComponent
                                                     }

                                    Component {
                                        id: thumbnailComponent
                                        Thumbnail {
                                            id: thumbnail
                                            width: Theme.itemSizeMedium
                                            height: Theme.itemSizeMedium
                                            sourceSize {
                                                width: width
                                                height: height
                                            }
                                            fillMode: Thumbnail.PreserveAspectCrop

                                            mimeType: modelData.mime
                                            source: modelData.path

                                            layer.enabled: gridItem.highlighted
                                            layer.effect: PressEffect { source: thumbnail }

                                            Loader {
                                                active: modelData.type == 1
                                                anchors.centerIn: parent
                                                width: Theme.iconSizeMedium
                                                height: Theme.iconSizeMedium
                                                sourceComponent: Component {
                                                    Icon {
                                                        source: "image://theme/icon-m-play"
                                                        anchors.fill: parent
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Component {
                                        id: iconComponent
                                        Icon {
                                            anchors.centerIn: parent
                                            source: Theme.iconForMimeType(modelData.mime)
                                        }
                                    }
                                }

                                onClicked: openMenu()
                                menu: Component {
                                    ContextMenu {
                                        MenuItem {
                                            text: modelData.spoiler ? qsTr("Remove spoiler") : qsTr("Hide with spoiler")
                                            onClicked: {
                                                attachments[index].spoiler = !attachments[index].spoiler
                                                attachmentsChanged()
                                            }
                                        }
                                        MenuItem {
                                            text: qsTr("Remove")
                                            onClicked: remove()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                FadeableFlickable {
                    id: attachActionsFlickable
                    width: parent.width
                    property bool opened
                    visible: opacity > 0
                    opacity: opened ? 1 : 0
                    height: opened ? attachActionsRow.height : 0
                    Behavior on height { SmoothedAnimation { duration: 200 } }
                    Behavior on opacity { OpacityAnimator { duration: 200 } }
                    contentHeight: attachActionsRow.height
                    contentWidth: Math.max(width, attachActionsRow.width)

                    function openPicker(path, type) {
                        var picker = pageStack.push('Sailfish.Pickers.'+path, {
                                                        allowedOrientations: page.allowedOrientations
                                                    })
                        picker.selectedContentPropertiesChanged.connect(function() {
                            attachActionsFlickable.opened = false
                            page.addAttachment(picker.selectedContentProperties, type)
                        })
                    }

                    Row {
                        id: attachActionsRow
                        spacing: Theme.paddingMedium

                        IconButton {
                            icon.source: "image://theme/icon-m-image"
                            onClicked: attachActionsFlickable.openPicker('ImagePickerPage', 0)
                        }
                        IconButton {
                            icon.source: "image://theme/icon-m-video"
                            onClicked: attachActionsFlickable.openPicker('VideoPickerPage', 1)
                        }
                        IconButton {
                            icon.source: "image://theme/icon-m-document"
                            onClicked: attachActionsFlickable.openPicker('FilePickerPage', 2)
                        }
                    }
                }

                Row {
                    width: parent.width
                    TextArea {
                        id: sendField
                        width: parent.width - sendButtons.width

                        placeholderText: qsTr("Type something")
                        hideLabelOnEmptyField: false
                        labelVisible: false
                        anchors.verticalCenter: parent.verticalCenter
                        backgroundStyle: TextEditor.UnderlineBackground
                        horizontalAlignment: TextEdit.AlignLeft

                        EnterKey.iconSource: appSettings.sendByEnter ? sendButton.icon.source : ""
                        EnterKey.onClicked: if (appSettings.sendByEnter) doSend()
                    }

                    Row {
                        id: sendButtons
                        IconButton {
                            // TODO (maybe): editing attachments (not possible in official clients though)
                            visible: attachPermission && currentFieldAction != 1
                            enabled: attachments.length < 10
                            width: Theme.iconSizeMedium + 2 * Theme.paddingSmall
                            height: width
                            anchors.bottom: parent.bottom
                            icon.source: "image://theme/icon-m-attach"
                            highlighted: down || attachActionsFlickable.opened
                            onClicked: attachActionsFlickable.opened = !attachActionsFlickable.opened
                        }

                        IconButton {
                            id: sendButton
                            visible: !appSettings.sendByEnter
                            width: visible ? (Theme.iconSizeMedium + 2 * Theme.paddingSmall) : 0
                            height: width
                            enabled: sendField.text.length !== 0
                            anchors.bottom: parent.bottom
                            icon.source: "image://theme/icon-m-" + (currentFieldAction == 1 ? "accept" : "send")

                            onClicked: doSend()
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

        function appendDemo2(toAppend) {
            insert(0, shared.combineObjects(shared.stubMessage, toAppend))
        }

        function appendDemo(isyou, thecontents, additionalOptions) {
            additionalOptions = additionalOptions !== undefined ? additionalOptions : {}
            appendDemo2(shared.combineObjects(
                            {sent: isyou, contents: thecontents, formattedContents: shared.markdown(thecontents, !!additionalOptions.flags && additionalOptions.flags.edit), author: isyou ? "you" : "notyou", avatar: "https://cdn.discordapp.com/embed/avatars/"+(isyou ? "0" : "1")+".png"},
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
            //appendDemo(true, "Hey everyone, look at this pic!", {attachments: [{}]})

            appendDemo(true, "# Markdown showcase:\n*Italic*, **bold**, ***both***, `code`, normal")
            appendDemo2({contents: "I am a normal guy, just have a colored nickname", formattedContents: "I am a normal guy, just have a colored nickname", author: "normal_guy", avatar: "https://cdn.discordapp.com/embed/avatars/4.png", flags: {color:"green"}})
            appendDemo2({contents: "I am a system guy", formattedContents: "I am a system guy", avatar: "https://cdn.discordapp.com/embed/avatars/3.png", flags: {system:true}})
            appendDemo2({contents: "I am a bot!", formattedContents: "I am a bot!", author: "a_bot", avatar: "https://cdn.discordapp.com/embed/avatars/2.png", flags: {bot:true}})
            appendDemo(true, "Edited message...", {flags: {edit: true}})
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
