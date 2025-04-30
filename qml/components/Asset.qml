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
    property string id

    property bool cachedSourceFailed: !cachedSource || cachedSource == 'None' // auto-fail if source is empty
    property string source: asset.cachedSourceFailed && asset.originalSource ? asset.originalSource : asset.cachedSource
    property bool forceStatic

    function updateFromData() {
        if (!info.stub) {
            console.log(JSON.stringify(info))
            cachedSource = info.source||''
            cachedSourceFailed = false
            originalSource = info.originalSource||''
            animated = info.animated||false
            imageType = info.type
            id = info.id
        }
    }

    Component.onCompleted: {
        py.setHandler('recache'+imageType+id, function(updated) { asset.info = updated })
        updateFromData()
    }
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
                                     py.call2('recache', [imageType, id, originalSource])
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
