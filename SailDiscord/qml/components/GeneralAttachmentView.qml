import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
// This file has logic for general attachment displaying functionality for all supported types.

Item {
    property var model
    property bool showSpoiler: true
    property bool zoomAllowed: false
    anchors.fill: parent

    Loader {
        anchors.fill: parent
        sourceComponent:
            switch (model.type) {
            case 1: return unknownPreview
            case 2: return zoomAllowed ? imageFullscreenPreview : imagePreview
            }
    }

    Component {
        id: imagePreview
        Item {
            Image {
                id: img
                source: model.url
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: !(model.spoiler && showSpoiler)

                Drag.active: dragArea.drag.active
                Drag.hotSpot.x: 10
                Drag.hotSpot.y: 10
            }

            FastBlur {
                visible: !img.visible
                anchors.fill: img
                source: img
                radius: 100

                Label {
                    text: qsTr("SPOILER")
                    anchors.centerIn: parent
                    font.bold: true
                    color: Theme.highlightColor
                }
            }
        }
    }

    Component {
        id: imageFullscreenPreview
        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: imageView.width
            contentHeight: imageView.height
            onHeightChanged: if (image.status == Image.Ready) image.fitToScreen()

            Item {
                id: imageView
                width: Math.max(image.width*image.scale, flick.width)
                height: Math.max(image.height*image.scale, flick.height)

                Image {
                    id: image
                    property real prevScale
                    property alias imageRotation: imageRotation

                    function fitToScreen() {
                        scale = Math.min(flick.width / width, flick.height / height)
                        pinchArea.minScale = scale
                        pinchArea.maxScale = 4*Math.max(flick.width / width, flick.height / height)
                        prevScale = scale
                    }

                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    smooth: !flick.moving
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    source: model.url

                    sourceSize.width: Math.max(Screen.width, Screen.height)
                    sourceSize.height: sourceSize.width

                    Behavior on opacity { FadeAnimator { duration: 250 } }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            fitToScreen()
                            statusLoader.sourceComponent = undefined
                        } else if (status === Image.Loading) {
                            statusLoader.sourceComponent = loadingIndicator
                        } else if (status === Image.Error) {
                            statusLoader.sourceComponent = failedLoading
                        }
                    }

                    onScaleChanged: {
                        if ((width * scale) > flick.width) {
                            var xoff = (flick.width / 2 + flick.contentX) * scale / prevScale;
                            flick.contentX = xoff - flick.width / 2
                        }
                        if ((height * scale) > flick.height) {
                            var yoff = (flick.height / 2 + flick.contentY) * scale / prevScale;
                            flick.contentY = yoff - flick.height / 2
                        }
                        prevScale = scale
                        flick.returnToBounds();
                    }

                    transform: [
                        Rotation {
                            id: imageRotation
                            origin { x: image.width/2; y: image.height/2 }

                            NumberAnimation on angle {
                                id: angleAnim; from: imageRotation.angle
                                onStopped: imageRotation.angle = to % 360
                            }

                            function rotateRight() {
                                angleAnim.to = angle+90;
                                angleAnim.duration = 150;
                                angleAnim.start();
                            }
                            function reset(to) {
                                if (Math.abs(angle-to) > 180) angleAnim.to = to+360;
                                else angleAnim.to = to;
                                angleAnim.duration = 150*(Math.abs((angle-angleAnim.to)/90));
                                angleAnim.start();
                            }
                        }
                    ]
                }
            }

            PinchArea {
                id: pinchArea
                property real minScale: 1.0
                property real maxScale: 3.0

                MouseArea {
                    property bool pinchRequested: false

                    anchors.fill: parent
                    Timer { id: timer; interval: 200; onTriggered: parent.singleClick() }
                    onClicked: timer.start()

                    onDoubleClicked: {
                        pinchRequested = true
                        if (image.status != Image.Ready) return;

                        var newScale = pinchArea.minScale;
                        if (Math.round(image.scale) === Math.round(pinchArea.minScale)) {
                            // image.fitToScreen() is called when the image is loaded. This makes
                            // sure that either height or width is fit to the flickable's corresponding
                            // side. We check which side fits and scale to the other.
                            var scaledWidth = Math.round(image.width*image.scale)
                            var scaledHeight = Math.round(image.height*image.scale)
                            var buffer = Theme.horizontalPageMargin

                            if (scaledWidth >= (flick.width-buffer) && scaledWidth <= (flick.width+buffer) &&
                                    scaledHeight >= (flick.height-buffer) && scaledHeight <= (flick.height+buffer)) {
                                // just zoom in if both sides fit (almost) exactly
                                newScale = pinchArea.maxScale
                            } else if (scaledWidth === flick.width) {
                                newScale = (flick.height-5)/image.height
                            } else if (scaledHeight === flick.height) {
                                newScale = (flick.width-5)/image.width
                            }
                        } else {
                            newScale = pinchArea.minScale;
                        }

                        pinchArea.zoomToScale(newScale, true);
                    }

                    function singleClick() {
                        if (pinchRequested) {
                            pinchRequested = false;
                            return;
                        } else if (_titleOverlayItem.visible) {
                            _titleOverlayItem.hide();
                        } else {
                            _titleOverlayItem.show();
                        }
                    }
                }

                anchors.fill: parent
                enabled: image.status == Image.Ready
                pinch.target: image
                pinch.minimumScale: 0.5*minScale
                pinch.maximumScale: 1.5*maxScale

                onPinchFinished: {
                    flick.returnToBounds()
                    if (image.scale < pinchArea.minScale) {
                        zoomToScale(pinchArea.minScale, false)
                    }
                    else if (image.scale > pinchArea.maxScale) {
                        zoomToScale(pinchArea.maxScale, false)
                    }
                }

                function zoomToScale(newScale, quick) {
                    if (quick === true) bounceBackAnimation.quick = true
                    else bounceBackAnimation.quick = false
                    bounceBackAnimation.to = newScale;
                    bounceBackAnimation.start()
                }

                NumberAnimation {
                    id: bounceBackAnimation
                    target: image
                    property bool quick: false
                    duration: quick ? 150 : 250
                    property: "scale"
                    from: image.scale
                }
            }
        }
    }

    Component {
        id: unknownPreview
        Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.centerIn: parent
            color: Theme.secondaryHighlightColor
            text: qsTr("Attachment unsupported: %1").arg('<font color="'+Theme.highlightColor+'">'+model.realtype+'</font>')
        }
    }
}
