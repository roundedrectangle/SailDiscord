import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/About"
import "../modules/Opal/Attributions"

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    property string userid
    property string name
    property string icon
    property date memberSince

    appName: name
    appIcon: icon == "None" ? "" : icon

    _pageHeaderItem.title: qsTranslate("About", "About", "User")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false
    description: ""
    appVersion: ""
    versionText.text: appVersion // a workaround in AboutPageBase, merging it to upstream is probably not a good idea...

    extraSections: [
        InfoSection {
            title: qsTr("Member since")
            text: Format.formatDate(memberSince, Formatter.DateFull)
        }

    ]

    Component.onCompleted: {
        python.setHandler("user"+userid, function(bio, _date, status, onMobile) {
            description = bio
            memberSince = new Date(_date)
            appVersion = ["",
                          qsTranslate("status", "Online"),
                          qsTranslate("status", "Offline"),
                          qsTranslate("status", "Do Not Disturb"),
                          qsTranslate("status", "Invisible"),
                          qsTranslate("status", "Idle")
                    ][status]
            if (onMobile && appVersion != "")
                appVersion += " "+qsTranslate("status", "(Phone)", "Used with e.g. Online (Phone)")
        })
        python.requestUserInfo(userid)
    }

}
