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
        width: parent.width
        height: childrenRect.height

        Image {
            id: profileIcon
            source: pfp
            //height: parent.height
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
            width: parent.width-(profileIcon.width+iconPadding.width)
            Label {
                text: author
                color: Theme.secondaryColor
            }

            Label {
                text: contents
                wrapMode: Text.Wrap
                width: parent.width
            }

            Item { height: Theme.paddingLarge; width: 1; }
        }
    }

    Component.onCompleted: {
        console.log(contents+"-"+sent)
    }
}
