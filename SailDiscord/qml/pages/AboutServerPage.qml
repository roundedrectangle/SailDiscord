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
    description: qsTr("Member count: ") + memberCount

    _pageHeaderItem.title: qsTranslate("AboutServer", "About", "Server")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false

    // Legacy mode...
    property bool _legacyMode
    PullDownMenu {
        parent: page.flickable
        enabled: serverid == "1261605062162251848"
        visible: enabled
        MenuItem {
            text: "Toggle legacy mode"
            onClicked: {
                appConfiguration.legacyMode = !appConfiguration.legacyMode
                Qt.quit()
            }
        }
    }
    extraSections: [
        InfoSection { visible: _legacyMode
            text: "Two members mode activated"
        },
        InfoSection { visible: _legacyMode
            title: "Third member"
            text: "Third member is @kozelderezel, which is developer's second account."
        }
    ]
    Component.onCompleted: _legacyMode = appConfiguration.legacyMode // Only activate once in a session
}
