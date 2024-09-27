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

    appName: name
    appIcon: icon == "None" ? "" : icon
    description: qsTr("Member count: ")+memberCount

    _pageHeaderItem.title: qsTranslate("AboutServer", "About", "Server")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false
}
