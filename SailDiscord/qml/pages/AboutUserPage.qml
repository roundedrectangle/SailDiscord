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

    extraSections: [
        InfoSection {
            title: qsTr("Member since")
            text: Format.formatDate(memberSince, Formatter.DateFull)
        }

    ]

    Component.onCompleted: {
        python.setHandler("user"+userid, function(bio, _date) {description = bio; memberSince = new Date(_date);})
        python.requestUserInfo(userid)
    }
}
