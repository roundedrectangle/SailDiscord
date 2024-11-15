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

    property string _memberCount
    property var _features: ({community:false, partnered:false, verified:false})

    appName: name
    appIcon: icon == "None" ? "" : icon
    description: qsTr("Member count: ") + _memberCount

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
        },
        // Additional data
        InfoSection {
            visible: _features.community || _features.partnered || _features.verified
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-home"
                    onClicked: Notices.show(qsTr("This server is a community server"), Notice.Short, Notice.Bottom)
                    visible: _features.community
                }
                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-company"
                    onClicked: Notices.show(qsTr("This server is a partnered server"), Notice.Short, Notice.Bottom)
                    visible: _features.partnered
                }
                IconButton {
                    icon.color: Theme.secondaryHighlightColor
                    icon.highlightColor: Theme.secondaryColor
                    icon.source: "image://theme/icon-m-acknowledge"
                    onClicked: Notices.show(qsTr("This server is a verified server"), Notice.Short, Notice.Bottom)
                    visible: _features.verified
                }
            }
        }

    ]

    // Load additional data
    BusyLabel {
        id: busyIndicator
        parent: flickable
        running: true
        onRunningChanged: _develInfoSection.parent.visible = !running
    }

    Component.onCompleted: {
        _develInfoSection.parent.visible = !busyIndicator.running
        _develInfoSection.parent.children[2].children[0].wrapMode = Text.Wrap // appName
        _features = {community:false, partnered:false, verified:false}
        _legacyMode = appConfiguration.legacyMode && serverid == "1261605062162251848" // Only activate once in a session
        python.request('request_server_info', 'serverinfo'+serverid, [serverid], function(memberCount, features) {
            if (_legacyMode) {
                memberCount = 2
                features.community = false
            }
            _memberCount = memberCount
            _features = features
            busyIndicator.running = false
        })
    }
}
