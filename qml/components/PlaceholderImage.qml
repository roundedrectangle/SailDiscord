import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    property string text: ''
    property bool extendedRadius: false

    id: root
    height: Theme.iconSizeLarge
    width: height
    radius: extendedRadius ? Math.min(width, height)/4 : Math.min(width, height)

    color: (Theme.colorScheme === Theme.LightOnDark) ? Theme.darkSecondaryColor : Theme.lightSecondaryColor
    opacity: 0.8

    // credit: fernschreiber
    function getReplacementString(replacementStringHint) {
        if (replacementStringHint.length > 2) {
            // Remove all emoji images
            var strippedText = replacementStringHint.replace(/\<[^>]+\>/g, "").trim();
            if (strippedText.length > 0) {
                var textElements = strippedText.split(" ");
                if (textElements.length > 1) {
                    return textElements[0].charAt(0) + textElements[textElements.length - 1].charAt(0);
                } else {
                    return textElements[0].charAt(0);
                }
            }
        }
        return replacementStringHint;
    }

    Label {
        text: getReplacementString(root.text)
        anchors.centerIn: parent
        color: Theme.primaryColor
        font.bold: true
        font.pixelSize: (root.height >= Theme.itemSizeSmall) ? Theme.fontSizeLarge : Theme.fontSizeMedium
    }
}
