import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/About"
import "../modules/Opal/Attributions"

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    property string serverid
    property string name
    property string icon
    property string memberCount

    property bool easterEgg: false

    appName: easterEgg ? "RoundedRectangle's server" : name
    appIcon: icon == "None" ? "" : (easterEgg ? Qt.resolvedUrl("../../images/%1.png".arg(Qt.application.name)) : icon)
    description: qsTr("Member count: ")+ (easterEgg ? 3 : memberCount)

    _pageHeaderItem.title: qsTranslate("AboutServer", "About", "Server")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false

    extraSections: InfoSection {
        visible: easterEgg
        title: "Third member"
        text: "Third member is @kozelderezel, which is developer's second account."
    }

    PullDownMenu {
        parent: page.flickable
        enabled: serverid == "1261605062162251848" && !easterEgg
        visible: enabled
        MenuItem {
            text: "Two members mode"
            onClicked: easterEgg = true
        }
    }
}
