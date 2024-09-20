import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property string title
    property string icon

    property bool hasIcon: icon != "None" && icon != ""

    property bool _iconAvailable: hasIcon || appSettings.emptySpace

    contentWidth: parent.width
    contentHeight: _iconAvailable ? Theme.itemSizeLarge : Theme.itemSizeSmall;

    Column {
        width: parent.width - Theme.horizontalPageMargin*2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Row {
            //spacing: _iconAvailable ? Theme.paddingLarge : 0

            Image {
                id: profileIcon
                source: hasIcon ? icon : ""
                height: (parent.parent.parent.height-4*Theme.paddingSmall)
                width: height

                visible: _iconAvailable

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

                onStatusChanged: if (status == Image.Error)
                    Notices.show(qsTranslate("Errors", "Error loading image %1. Please report this to developers").arg(title), Notice.Long, Notice.Top)

                ProgressCircle {
                    id: progressCircle
                    anchors.fill: parent
                    visible: parent.status == Image.Loading

                    Timer {
                        interval: 32
                        repeat: true
                        onTriggered: progressCircle.value = (progressCircle.value + 0.01) % 1.0
                        running: parent.parent.status == Image.Loading
                    }
                }
            }

            Item { id: iconPadding; height: 1; width: _iconAvailable ? Theme.paddingLarge : 0; }

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
    }
}
