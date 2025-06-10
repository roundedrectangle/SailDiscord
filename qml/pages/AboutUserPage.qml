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
    property var icon
    property bool isClient: false
    property bool pulleyMenuVisible: !isClient
    property bool showSettings: isClient
    property bool loading: false
    property alias _busyIndicator: busyIndicator

    property bool _loaded: false
    property date memberSince
    property string _status
    property bool isBot: false
    property bool isSystem: false
    property bool isFriend: false
    property string globalName: ""
    property string username: ""

    on_StatusChanged: _develInfoSection.parent.children[2].children[1].text = _status // this modifies the Version %1 text

    appName: name
    appIcon: icon.source || ''

    _pageHeaderItem.title: qsTranslate("AboutUser", "About", "User")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false
    appVersion: _status != "" ? 'a' : '' // makes it visible
    //licenses: License {spdxId: "WTFPL"} // suppress No license errors

    Loader {
        sourceComponent: pulleyMenuVisible ? pullMenuComponent : null
        Component {
            id: pullMenuComponent
            PullDownMenu {
                visible: !isFriend && appSettings.friendRequests
                parent: page.flickable
                MenuItem {
                    visible: !isFriend && appSettings.friendRequests
                    text: qsTr("Send friend request")
                    onClicked: py.call('main.comm.send_friend_request', [userid])
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
        onRunningChanged: _develInfoSection.parent.visible = !running && _loaded
    }

    MouseArea {
        parent: _iconItem
        anchors.fill: parent
        onClicked: pageStack.push("FullscreenAttachmentPage.qml", {model: shared.arrayToListModel(page, [{
            spoiler: false,
            filename: name+"_"+userid+'.'+icon.extension,
            _height: _iconItem.sourceSize.height,
            maxheight: _iconItem.sourceSize.height,
            maxwidth: _iconItem.sourceSize.width,
            type: icon.animated ? 3 : 2,
            realtype: 'image/'+icon.extension,
            url: icon.source,
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
        },
        InfoSection {
            id: settingsSection
            title: qsTr("Settings")
            visible: showSettings
            Loader {
                id: settingsLoader
                parent: settingsSection
                width: parent.width
                height: item ? item.sections.height : 0
                active: showSettings
                sourceComponent: Component {
                    SettingsPage {
                        sections.parent: settingsLoader
                    }
                }
            }
        }

    ]

    function load() {
        if (_loaded || loading) return
        _loaded = true
        _develInfoSection.parent.visible = !busyIndicator.running && _loaded
        py.call2('request_user_info', userid) // for client, it will be -1
    }

    Component.onCompleted: {
        _develInfoSection.parent.visible = !busyIndicator.running && _loaded
        _develInfoSection.parent.children[3].textFormat = Text.RichText // description
        _develInfoSection.parent.children[2].children[0].wrapMode = Text.Wrap // appName
        _develInfoSection.parent.children[3].linkActivated.connect(function(link) {
            // Workaround for replacing default ExternalUrlPage with the latest LinkHandler
            pageStack.completeAnimation()
            pageStack.pop(undefined, PageStackAction.Immediate)
            LinkHandler.openOrCopyUrl(link)
        })
        py.setHandler("user"+(isClient?"":userid), function(bio, date, status, onMobile, allNames) {
            description = shared.markdown(bio, _develInfoSection.parent.children[3].linkColor)
            memberSince = new Date(date)
            _status = shared.constructStatus(status, onMobile)
            busyIndicator.running = false
            // by default these are empty strings:
            globalName = allNames.global
            username = allNames.username

            if (!isClient) /*{
                page.icon = arguments[5]
            } else*/ {
                isBot = arguments[5]
                isSystem = arguments[6]
                isFriend = arguments[7]
                if (arguments[8]) _develInfoSection.parent.children[2].children[0].color = arguments[8]
            }
        })
        load()
    }
    onLoadingChanged: load()

    Component.onDestruction: py.setHandler("user"+(isClient?"":userid), function() {})
}
