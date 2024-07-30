import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string contents
    property string author
    property string pfp
    property bool sent // If the message is sent by the user connected to the client

    width: parent.width
    contentHeight: row.height

    Row {
        id: row
        width: Math.min(parent.width, profileIcon.width+iconPadding.width+Math.max(contentsLbl.implicitWidth, authorLbl.width))
        height: childrenRect.height
        anchors.right: sent ? parent.right : undefined

        Image {
            id: profileIcon
            source: pfp
            height: Theme.iconSizeLarge
            width: height

            property bool rounded: true
            property bool adapt: true

            layer.enabled: rounded
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: profileIcon.width
                    height: profileIcon.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: profileIcon.adapt ? profileIcon.width : Math.min(profileIcon.width, profileIcon.height)
                        height: profileIcon.adapt ? profileIcon.height : width
                        radius: Math.min(width, height)
                    }
                }
            }
        }

        Item { id: iconPadding; height: 1; width: Theme.paddingLarge; }

        Column {
            id: textContainer
            width: Math.min(parent.width-(profileIcon.width+iconPadding.width), Math.max(contentsLbl.paintedWidth, authorLbl.width))
            Label {
                id: authorLbl
                text: author
                color: Theme.secondaryColor
            }

            Label {
                id: contentsLbl
                text: contents
                wrapMode: Text.Wrap
                width: parent.width
            }

            Item { height: Theme.paddingLarge; width: 1; }
        }
    }
}
