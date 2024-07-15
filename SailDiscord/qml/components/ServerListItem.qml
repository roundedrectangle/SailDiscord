import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string title
    property string icon

    width: parent.width
    //ListView.view.width
    height: Theme.itemSizeLarge

    //Label {
    //    text: name
    //}

    Column {
        Row {
            Image {
                id: profileIcon
                source: icon
                //height: parent.height
                height: parent.parent.parent.height-4*Theme.paddingSmall
                width: height

                anchors {

                }

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

            Label {
                //x: Theme.horizontalPageMargin
                //width: parent.width - 2 * x
                //anchors.verticalCenter: parent.verticalCenter
                text: title
                //truncationMode: TruncationMode.Fade
                //font.capitalization: Font.Capitalize

                anchors {
                    left: profileIcon.right
                    leftMargin: Theme.paddingLarge
                }
            }
        }

        Separator {
            color: Theme.primaryColor
            horizontalAlignment: Qt.AlignHCenter
        }
    }
}
