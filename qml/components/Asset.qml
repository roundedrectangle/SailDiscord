import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: asset
    asynchronous: true

    property var info: [] // see caching.py/STUB_QML_ASSET
    property bool forceStatic
    property bool pauseAnimation

    property var _info: info ? (
                                   Array.isArray(info)
                                   ? info
                                   : shared.listModelToArray(info)
                               ) : null
    readonly property bool valid: !!(_info && _info[0])
    property bool cachedSourceFailed: (_info && !valid) // if info is undefined (just loaded), don't automatically fail
    property string source: ((asset.cachedSourceFailed && _info && _info[1]) ? _info[1] : _info[0]) || ''

    readonly property var imageStatus: item ? item.status : Image.Loading

    sourceComponent: _info && _info[0] ?
                         (!forceStatic && _info && _info[2] ? animatedComponent : staticComponent)
                       : null
    onImageStatusChanged: if (imageStatus == Image.Error) cachedSourceFailed = true

    on_InfoChanged: console.log(JSON.stringify(_info))

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
