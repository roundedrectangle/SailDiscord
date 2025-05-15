import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: asset
    asynchronous: true

    property var info: ({})
    property bool forceStatic
    property bool pauseAnimation

    property bool cachedSourceFailed: info && info.available && (!info.source || info.source === 'None') // auto-fail if source is empty
    property string source: (asset.cachedSourceFailed && info && info.originalSource) ? info.originalSource : info.source
    property string lastHandler

    readonly property var imageStatus: item ? item.status : Image.Loading

    function updateFromData() {
        if (info && info.available) {
            cachedSourceFailed = false
            if (lastHandler) py.setHandler(lastHandler, undefined)
            lastHandler = 'recache'+info.type+info.id
            py.setHandler(lastHandler, function(updated) { asset.info = updated; updateFromData() })
        } else cachedSourceFailed = true
    }

    Component.onCompleted: updateFromData()
    Component.onDestruction: if (lastHandler) py.setHandler(lastHandler, undefined)
    onInfoChanged: updateFromData()

    sourceComponent: info && info.available ?
                         (!forceStatic && info && info.animated ? animatedComponent : staticComponent)
                       : null

    onImageStatusChanged: if (status == Image.Error && !asset.cachedSourceFailed) {
                              asset.cachedSourceFailed = true
                              py.call2('recache', [info.type, info.id, info.originalSource])
                          }

    Component {
        id: staticComponent
        Image {
            anchors.fill: parent
            asynchronous: true
            source: (!asset.source || asset.source == 'None') ? '' : asset.source
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
            source: !asset.source || asset.source == 'None' ? '' : asset.source
            /*sourceSize {
                width: width
                height: height
            }*/
        }
    }
}
