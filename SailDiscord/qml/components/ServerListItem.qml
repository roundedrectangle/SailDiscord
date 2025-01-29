import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    id: root
    property string serverid
    property string title
    property string placeholderBase
    property string icon
    property bool defaultActions: true
    property bool textHighlighted
    property int mentionCount

    property bool _iconAvailable: (icon != "None" && icon != "")

    contentWidth: parent.width
    contentHeight: Theme.itemSizeLarge

    Row {
        width: parent.width - Theme.horizontalPageMargin*2
        anchors.centerIn: parent
        spacing: Theme.paddingLarge

        Loader {
            id: profileIcon
            width: root.contentHeight - Theme.paddingSmall*4
            height: width
            sourceComponent: _iconAvailable ? serverImageComponent : serverImagePlaceholderComponent
            Component {
                id: serverImageComponent
                ListImage {
                    id: profileIcon
                    icon: root.icon
                    anchors.fill: parent
                    forceVisibility: true
                    errorString: title
                }
            }
            Component {
                id: serverImagePlaceholderComponent
                PlaceholderImage {
                    text: placeholderBase || title
                    anchors.fill: parent
                }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - profileIcon.width - channelUnreadCount.width - parent.spacing*(channelUnreadCount.visible ? 2 : 1)
            truncationMode: TruncationMode.Fade
            text: title
            textFormat: appSettings.twemoji ? Text.RichText : Text.PlainText
            highlighted: textHighlighted || root.highlighted
        }

        Rectangle {
            id: channelUnreadCount
            visible: mentionCount > 0
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? children[0].width + Theme.paddingSmall*2 : 0
            height: children[0].height + Theme.paddingSmall*2
            radius: height/2
            color: Theme.highlightColor
            Label {
                text: mentionCount > 100000 ? '100k+' : mentionCount
                color: Theme.primaryColor
                anchors.centerIn: parent
            }
        }
    }

    onClicked: if (defaultActions) pageStack.push(Qt.resolvedUrl("../pages/ChannelsPage.qml"), { serverid: serverid, name: title, icon: image })
    menu: Component { ContextMenu {
        visible: defaultActions
        MenuItem {
            text: qsTranslate("AboutServer", "About", "Server")
            onClicked: pageStack.push(Qt.resolvedUrl("../pages/AboutServerPage.qml"),
                                      { serverid: serverid, name: title, icon: image }
                                      )
        }
        MenuItem {
            text: qsTranslate("General", "Copy server ID")
            visible: appSettings.developerMode
            onClicked: Clipboard.text = serverid
        }
    } }
}
