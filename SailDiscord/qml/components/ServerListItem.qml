import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string title
    property string icon

    property bool hasIcon: icon != "None"

    contentWidth: parent.width
    contentHeight: Theme.itemSizeLarge;

    Column {
        width: parent.width - Theme.horizontalPageMargin*2
        //height: parent.height - Theme.paddingLarge*2
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingSmall

        Row {
            //spacing: (hasIcon || appSettings.emptySpace) ? Theme.paddingLarge : 0

            Image {
                id: profileIcon
                source: hasIcon ? icon : ""
                height: parent.parent.parent.height-4*Theme.paddingSmall
                width: height

                visible: hasIcon || appSettings.emptySpace

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

            Item { id: iconPadding; height: 1; width: (hasIcon || appSettings.emptySpace) ? Theme.paddingLarge : 0; }

            Label {
                //width: (parent.width - profileIcon.width - iconPadding.width)
                text: title
                //fontSizeMode: Text.HorizontalFit
                //minimumPixelSize: 1
                //font.pixelSize: 50

                //truncationMode: TruncationMode.Fade
                //horizontalAlignment: Text.AlignLeft

                //anchors.horizontalCenter: parent.horizontalCenter
                //horizontalAlignment: Text.AlignLeft
                //truncationMode: TruncationMode.Fade
            }
        }

        Separator {
            color: Theme.primaryColor
            width: parent.width
            horizontalAlignment: Qt.AlignHCenter
        }
    }

}
