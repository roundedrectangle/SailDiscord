import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: asset
    asynchronous: true

    property var info: ({}) // see caching.py/STUB_QML_ASSET
    property bool forceStatic
    property bool pauseAnimation

    readonly property bool valid: !!(info && info.source)
    property bool cachedSourceFailed: !!info && !valid // if info is undefined (just loaded), don't automatically fail
    readonly property string defaultSource: ((asset.cachedSourceFailed && info && info.originalSource) ? info.originalSource : info.source) || ''
    property string source: defaultSource

    readonly property int imageStatus: item ? item.status : Image.Loading

    active: info && info.source
    sourceComponent: !forceStatic && info && info.animated ? animatedComponent : staticComponent
    onImageStatusChanged: if (imageStatus == Image.Error) cachedSourceFailed = true

    Component {
        id: staticComponent
        Image {
            anchors.fill: parent
            asynchronous: true
            source: asset.source
            sourceSize {
                width: width
                height: height
            }
        }
    }
    Component {
        id: animatedComponent
        AnimatedImage {
            anchors.fill: parent
            asynchronous: true
            playing: !pauseAnimation && shared.active
            source: asset.source
            /*sourceSize {
                width: width
                height: height
            }*/
        }
    }
}
