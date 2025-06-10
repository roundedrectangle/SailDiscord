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
    property string source: ((asset.cachedSourceFailed && info && info.originalSource) ? info.originalSource : info.source) || ''

    readonly property var imageStatus: item ? item.status : Image.Loading

    sourceComponent: info && info.source ?
                         (!forceStatic && info && info.animated ? animatedComponent : staticComponent)
                       : null
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
