import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: asset
    asynchronous: true

    //property string errorString
    property var info: {stub: true}

    property string cachedSource
    property string originalSource
    property bool animated
    property int imageType
    property string assetId

    property bool cachedSourceFailed: !cachedSource || cachedSource == 'None' // auto-fail if source is empty
    property string source: asset.cachedSourceFailed && asset.originalSource ? asset.originalSource : asset.cachedSource
    property bool forceStatic
    property string lastHandler

    function updateFromData() {
        if (!!info && !info.stub && info.available) {
            console.log(JSON.stringify(info))
            cachedSource = info.source||''
            cachedSourceFailed = false
            originalSource = info.originalSource||''
            animated = info.animated||false
            imageType = info.type
            assetId = info.id

            if (lastHandler) py.setHandler(lastHandler, undefined)
            lastHandler = 'recache'+imageType+assetId
            py.setHandler(lastHandler, function(updated) { asset.info = updated })
        }
    }

    Component.onCompleted: updateFromData()
    Component.onDestruction: py.setHandler(lastHandler, undefined)
    onInfoChanged: updateFromData()

    sourceComponent: animated && !forceStatic ? animatedComponent : staticComponent

    Component {
        id: staticComponent
        Image {
            anchors.fill: parent
            asynchronous: true
            source: !asset.source || asset.source == 'None' ? '' : asset.source
            onStatusChanged: if (status == Image.Error) {
                                 if (!asset.cachedSourceFailed) {
                                     asset.cachedSourceFailed = true
                                     py.call2('recache', [imageType, assetId, originalSource])
                                     //shared.imageLoadError(errorString)
                                 } else {
                                     // TODO: display fallback image or something
                                 }
                             }
        }
    }
    Component {
        id: animatedComponent
        AnimatedImage {
            anchors.fill: parent
            asynchronous: true
            source: asset.cachedSourceFailed && asset.originalSource ? asset.originalSource : asset.source
        }
    }
}
