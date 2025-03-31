import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    /*CoverPlaceholder {
        icon.source: ""
        text: "Sailcord"
    }*/

    Image {
        anchors {
            verticalCenter: parent.verticalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
        source: Qt.resolvedUrl('../../images/cover_grayscale.png')
        opacity: 0.15
        fillMode: Image.PreserveAspectFit
        width: parent.height - Theme.paddingLarge
        height: width
    }

    Label {
        text: "Sailcord"
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.highlightColor
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge*5
            horizontalCenter: parent.horizontalCenter
        }
    }
}
