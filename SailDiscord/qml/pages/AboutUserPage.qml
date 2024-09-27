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

    property date memberSince
    property string _status

    on_StatusChanged: _develInfoSection.parent.children[2].children[1].text = _status // this modifies the Version %1 text

    appName: name
    appIcon: icon == "None" ? "" : icon

    _pageHeaderItem.title: qsTranslate("About", "About", "User")
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
            title: qsTr("Member since")
            text: Format.formatDate(memberSince, Formatter.DateFull)
        }
    ]

    Component.onCompleted: {
        python.setHandler("user"+(isClient?"":userid), function(bio, _date, status, onMobile, icon) {
            description = bio
            memberSince = new Date(_date)
            _status = constructStatus(status, onMobile)
            busyIndicator.running = false
            if (icon != undefined) page.icon = icon
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
