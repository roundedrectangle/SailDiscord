import QtQuick 2.0
import '../modules/js/thumbhash.js' as ThumbHash

Loader {
    anchors.fill: parent

    property string placeholder

    property bool show
    active: placeholder && show

    sourceComponent: Component {
        Image {
            anchors.fill: parent
            source: ThumbHash.thumbHashBase64ToDataUrl(placeholder)
        }
    }
}
