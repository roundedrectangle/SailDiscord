import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../modules/Opal/About"

// This code uses some hacky ways to modify Opal.About to make it work with a user. Opal.About was not designed for this

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    property string userid: "-1"
    property string name
    property string icon
    property bool isClient: false
    property bool nicknameGiven: false

    property date memberSince
    property string _status
    property bool isBot: false
    property bool isSystem: false
    property string username: ""

    on_StatusChanged: _develInfoSection.parent.children[2].children[1].text = _status // this modifies the Version %1 text

    appName: name
    appIcon: icon == "None" ? "" : icon

    _pageHeaderItem.title: qsTranslate("AboutUser", "About", "User")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false
    appVersion: _status != "" // makes it visible
    licenses: License {spdxId: "WTFPL"} // suppress No license errors

    BusyLabel {
        id: busyIndicator
        parent: flickable
        running: true
        onRunningChanged: _develInfoSection.parent.visible = !running
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
            title: qsTr("Username")
            visible: username
            text: username
        },
        InfoSection {
            title: qsTr("Discord member since")
            text: Format.formatDate(memberSince, Formatter.DateFull)
        }
    ]

    Component.onCompleted: {
        _develInfoSection.parent.visible = !busyIndicator.running
        python.setHandler("user"+(isClient?"":userid), function(bio, _date, status, onMobile) {
            description = bio
            memberSince = new Date(_date)
            _status = constructStatus(status, onMobile)
            busyIndicator.running = false
            if (isClient) {
                page.icon = arguments[4]
            } else {
                username = nicknameGiven ? arguments[4] : ''
                isBot = arguments[5]
                isSystem = arguments[6]
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
