import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../modules/Opal/About"
import "../modules/Opal/LinkHandler"

// This code uses some hacky ways to modify Opal.About to make it work with a user. Opal.About was not designed for this

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    property string userid: "-1"
    property string name
    property string icon
    property bool isClient: false
    property bool pulleyMenuVisible: !isClient

    property date memberSince
    property string _status
    property bool isBot: false
    property bool isSystem: false
    property bool isFriend: false
    property string globalName: ""
    property string username: ""

    on_StatusChanged: _develInfoSection.parent.children[2].children[1].text = _status // this modifies the Version %1 text

    appName: name
    appIcon: icon == "None" ? "" : icon

    _pageHeaderItem.title: qsTranslate("AboutUser", "About", "User")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false
    appVersion: _status != "" ? 'a' : '' // makes it visible
    licenses: License {spdxId: "WTFPL"} // suppress No license errors

    Loader {
        sourceComponent: pulleyMenuVisible ? pullMenuComponent : null
        Component {
            id: pullMenuComponent
            PullDownMenu {
                parent: page.flickable
                MenuItem {
                    visible: !isFriend
                    text: qsTr("Send friend request")
                    onClicked: python.call('main.comm.send_friend_request', [userid])
                }
                /*MenuItem {
                    visible: !isClient
                    text: qsTr("Message")
                }*/
            }
        }
    }

    BusyLabel {
        id: busyIndicator
        parent: flickable
        running: true
        onRunningChanged: _develInfoSection.parent.visible = !running
    }

    MouseArea {
        parent: _iconItem
        anchors.fill: parent
        onClicked: pageStack.push("FullscreenAttachmentPage.qml", {model: shared.attachmentsToListModel(page, [{
            spoiler: false,
            filename: name+"_"+userid+'.png',
            _height: _iconItem.sourceSize.height,
            maxheight: _iconItem.sourceSize.height,
            maxwidth: _iconItem.sourceSize.width,
            type: 2,
            realtype: 'image/png',
            url: icon,
            alt: ""
        }])})
    }

    extraSections: [
        InfoSection {
            visible: isBot || isSystem
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-device-lock"
                    onClicked: Notices.show(qsTr("This user is a system account"), Notice.Short, Notice.Bottom)
                    visible: isSystem
                }
                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-game-controller"
                    onClicked: Notices.show(qsTr("This user is a bot"), Notice.Short, Notice.Bottom)
                    visible: isBot
                }
                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-game-controller"
                    onClicked: Notices.show(qsTr("This user is a bot"), Notice.Short, Notice.Bottom)
                    visible: isBot
                }
            }
        },
        InfoSection {
            title: qsTr("Global nickname")
            visible: text
            text: globalName
        },
        InfoSection {
            title: qsTr("Username")
            visible: text
            text: username
        },
        InfoSection {
            title: qsTr("Discord member since")
            text: Format.formatDate(memberSince, Formatter.DateFull)
        }
    ]

    Component.onCompleted: {
        _develInfoSection.parent.visible = !busyIndicator.running
        _develInfoSection.parent.children[3].textFormat = Text.RichText // description
        _develInfoSection.parent.children[2].children[0].wrapMode = Text.Wrap // appName
        _develInfoSection.parent.children[3].linkActivated.connect(function(link) {
            // Workaround for replacing default ExternalUrlPage with the latest LinkHandler
            pageStack.completeAnimation()
            pageStack.pop(undefined, PageStackAction.Immediate)
            LinkHandler.openOrCopyUrl(link)
        })
        python.setHandler("user"+(isClient?"":userid), function(bio, _date, status, onMobile, allNames) {
            description = shared.markdown(bio, _develInfoSection.parent.children[3].linkColor)
            memberSince = new Date(_date)
            _status = constructStatus(status, onMobile)
            busyIndicator.running = false
            // by default these are empty strings:
            globalName = allNames.global
            username = allNames.username

            if (isClient) {
                page.icon = arguments[5]
            } else {
                isBot = arguments[5]
                isSystem = arguments[6]
                isFriend = arguments[7]
                if (arguments[8]) _develInfoSection.parent.children[2].children[0].color = arguments[8]
            }
        })
        python.requestUserInfo(userid) // for client, it will be -1
    }

    function constructStatus(statusIndex, onMobile) {
        var result = ["",
                      qsTranslate("status", "Online"),
                      qsTranslate("status", "Offline"),
                      qsTranslate("status", "Do Not Disturb"),
                      qsTranslate("status", "Invisible"),
                      qsTranslate("status", "Idle")
                ][statusIndex]
        if (onMobile && result !== "")
            result += " "+qsTranslate("status", "(Phone)", "Used with e.g. Online (Phone)")
        return result
    }
}
