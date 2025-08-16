import QtQuick 2.5
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
// This file has logic for general attachment displaying functionality for all supported types.

Item {
    id: root
    property var model
    property bool fullscreen: false
    anchors.fill: parent

    signal toggleControls

    Loader {
        anchors.fill: parent
        sourceComponent:
            switch (model.type) {
            case 0: return fullscreen ? unknownFullscreenPreview : unknownPreview
            case 1: case 2: return fullscreen ? imageFullscreenPreview : imagePreview
            }
    }

    Component {
        id: imagePreview
        Item {
            Loader {
                id: img
                anchors.fill: parent
                sourceComponent: model.type == 3 ? animImg : normalImg
                onItemChanged: {
                    item.source = model.url
                    item.anchors.fill = item.parent
                    item.fillMode = Image.PreserveAspectFit
                }

                Component { id: normalImg; Image {} }
                Component { id: animImg; AnimatedImage {} }
            }

			Loader {
				id: blur
				anchors.fill: img
				active: model.spoiler && !dismissed && !fullscreen
				property bool dismissed
				
	            sourceComponent: Component {
		            FastBlur {
		                anchors.fill: parent
		                source: img.item
		                radius: 100

		                Label {
		                    text: qsTr("SPOILER")
		                    font.pixelSize: Theme.fontSizeHuge
		                    anchors.centerIn: parent
		                    font.bold: true
		                    color: Theme.highlightColor
		                }
		                
		                MouseArea {
		                	anchors.fill: parent
                            onClicked: blur.dismissed = true
		                }
		            }
		    	}
            }
        }
    }

    Component {
        id: imageFullscreenPreview
        ZoomableImage {
            source: model.url
            isAnimated: model.type == 3
            onToggleControls: root.toggleControls()
        }
    }

    Component {
        id: unknownFullscreenPreview
        Label {
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.horizontalPageMargin
            width: parent.width-2*x
            wrapMode: Text.Wrap
            color: Theme.secondaryHighlightColor
            text: qsTr("Attachment unsupported: %1").arg('<font color="'+Theme.highlightColor+'">'+model.realtype+'</font>')
        }
    }

    Component {
        id: unknownPreview
        Item {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            height: parent.height

			property bool spoilerDismissed
            
            Rectangle {
                anchors.fill: parent
                color: Theme.colorScheme === Theme.LightOnDark ? Theme.secondaryColor : Theme.overlayBackgroundColor
                opacity: 0.1
                radius: parent.width / 50
            }

            Row {
                anchors {
                    margins: Theme.paddingLarge
                    fill: parent
                }
                spacing: Theme.paddingLarge
                Icon {
                    id: unknownPreviewIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: Theme.iconForMimeType(model.realtype)
                }
                Label {
                	id: unknownPreviewLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - unknownPreviewIcon.width - parent.spacing*1
                    truncationMode: TruncationMode.Fade
                    text: model.filename
                }
            }

            states: [
	           	State {
	           		name: "spoiler"
	           		when: model.spoiler && !spoilerDismissed
	           		
	           		PropertyChanges {
	           			target: unknownPreviewLabel
	           			text: qsTr("SPOILER")
	           			font.bold: true
	           			color: Theme.highlightColor
	           		}
	           		
	           		PropertyChanges {
	           			target: unknownPreviewIcon
	           			source: "image://theme/icon-m-question"
	           		}

	           		PropertyChanges {
	           			target: spoilerMouseArea
	           			enabled: true
	           		}
	           	}
	        ]

            MouseArea {
            	id: spoilerMouseArea
            	anchors.fill: parent
            	enabled: false
            	onClicked: spoilerDismissed = true
            }
        }
    }
}
