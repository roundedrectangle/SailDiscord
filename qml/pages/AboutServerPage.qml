import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/About"
import "../modules/Opal/Attributions"
import "../js/shared.js" as Shared

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    property string serverid
    property string name
    property var icon

    property string _memberCount
    property string _onlineCount
    property var _features: ({community:false, partnered:false, verified:false})

    property string compiledMemberInfo: (_onlineCount != '-1' ? ('<font color="'+Theme.highlightColor+'">'+qsTr("%1 online").arg(_onlineCount)+"</font> ") : "")+
                                        (_memberCount != '-1' ? ('<font color="'+Theme.secondaryHighlightColor+'">'+qsTr("%1 members").arg(_memberCount)+"</font>") : "")
                       /*description: ((_onlineCount != '-1' && _memberCount != '-1') ? '<font color="green">●</font> ' : "")+
                       (_onlineCount != '-1' ? qsTr("%1 online").arg(_onlineCount) : "")+
                       ((_onlineCount != '-1' && _memberCount != '-1') ? '  <font color="gray">●</font> ' : "")+
                       (_memberCount != '-1' ? qsTr("%1 members").arg(_memberCount) : "")*/
    appVersion: !!compiledMemberInfo ? 'a' : '' // makes it visible
    onCompiledMemberInfoChanged: _develInfoSection.parent.children[2].children[1].text = compiledMemberInfo

    appName: name
    appIcon: icon.source || ''

    _pageHeaderItem.title: qsTranslate("AboutServer", "About", "Server")
    _licenseInfoSection.visible: false
    _develInfoSection.visible: false

    MouseArea {
        parent: _iconItem
        anchors.fill: parent
        onClicked: pageStack.push("FullscreenAttachmentPage.qml", {model: Shared.arrayToListModel(page, [{
            spoiler: false,
            filename: name+"_"+serverid+'.'+icon.extension,
            _height: _iconItem.sourceSize.height,
            maxheight: _iconItem.sourceSize.height,
            maxwidth: _iconItem.sourceSize.width,
            type: icon.animated ? 3 : 2,
            realtype: 'image/'+icon.extension,
            url: icon.source,
            alt: ""
        }])})
    }

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
        _develInfoSection.parent.children[3].textFormat = Text.RichText // description
        _develInfoSection.parent.children[2].children[0].wrapMode = Text.Wrap // appName
        _develInfoSection.parent.children[3].linkActivated.connect(function(link) {
            // Workaround for replacing default ExternalUrlPage with the latest LinkHandler
            pageStack.completeAnimation()
            pageStack.pop(undefined, PageStackAction.Immediate)
            LinkHandler.openOrCopyUrl(link)
        })

        _features = {community:false, partnered:false, verified:false}
        _legacyMode = appConfiguration.legacyMode && serverid == "1261605062162251848" // Only activate once in a session
        py.request('request_server_info', 'serverinfo'+serverid, [serverid], function(memberCount, onlineCount, features, desc) {
            if (_legacyMode) {
                memberCount = 3
                onlineCount = 1
                features.community = false
            }
            _memberCount = memberCount
            _onlineCount = onlineCount
            _features = features
            description = Shared.markdown(desc, _develInfoSection.parent.children[3].linkColor)
            busyIndicator.running = false
        })
    }
}
