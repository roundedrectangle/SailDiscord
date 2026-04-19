import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6

BackgroundItem {
    // TODO: spoilers, caching

    property var embed

    width: parent.width
    height: column.height
    contentItem.color: highlighted
                       ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                       : Theme.rgba(Theme.overlayBackgroundColor, 0.5)
    contentItem.radius: Theme.paddingSmall

    enabled: embed.url

    onClicked:
        Qt.openUrlExternally(embed.url)

    Column {
        id: column
        x: Theme.paddingMedium
        width: parent.width - 2*x
        topPadding: Theme.paddingMedium
        bottomPadding: Theme.paddingMedium
        spacing: Theme.paddingMedium

        Label {
            width: parent.width
            visible: !!text
            text: shared.emojify(embed.provider.name)
            font.pixelSize: Theme.fontSizeExtraSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            highlighted: providerMouseArea.containsPress
            truncationMode: TruncationMode.Fade
            MouseArea {
                id: providerMouseArea
                anchors.fill: parent
                enabled: embed.provider.url
                onClicked: Qt.openUrlExternally(embed.provider.url)
            }
        }

        EmbedImageText {
            text: shared.emojify(embed.author.name)
            icon.source: embed.author.icon
            icon.visible: embed.author.icon

            highlighted: authorMouseArea.containsPress
            MouseArea {
                id: authorMouseArea
                anchors.fill: parent
                enabled: embed.author.url
                onClicked: Qt.openUrlExternally(embed.author.url)
            }
        }

        Label {
            width: parent.width
            visible: !!text
            text: shared.emojify(embed.title)
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.highlightColor
            truncationMode: TruncationMode.Fade
        }

        Label {
            width: parent.width
            visible: !!text
            text: shared.emojify(embed.description)
            font.pixelSize: Theme.iconSizeExtraSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            maximumLineCount: 3
            truncationMode: TruncationMode.Elide
        }

        Item {
            width: parent.width
            height: Math.max(imageLoader.height, videoLoader.height)
            Loader {
                id: imageLoader
                property var imageData: embed.image.url ? embed.image : embed.thumbnail

                width: parent.width
                height: visible ? (width * imageData.aspectRatio) : 0
                active: imageData.url && (!videoLoader.active
                                          || (videoLoader.item && videoLoader.item.playbackState === MediaPlayer.StoppedState))
                visible: active
                sourceComponent: Component {
                    Image {
                        anchors.fill: parent
                        source: imageData.url

                        // FIXME!
                        /*EmbedPlaceholder {
                            placeholder: imageData.placeholder
                            show: parent.status == Image.Loading
                        }*/
                    }
                }
            }

            Loader {
                id: videoLoader
                width: parent.width
                height: visible ? (width * embed.video.aspectRatio) : 0
                active: appSettings.animateEmbeddedGifs && embed.provider.name !== 'YouTube' && embed.video.url
                visible: active
                sourceComponent: Component {
                    Video {
                        anchors.fill: parent
                        source: embed.video.url
                        autoPlay: false

                        VideoControls {
                            anchors.fill: parent
                            video: parent
                        }

                        // FIXME!
                        /*EmbedPlaceholder {
                            placeholder: embed.video.placeholder
                            show: parent.status == MediaPlayer.Loading
                        }*/
                    }
                }
            }
        }

        Repeater {
            model: embed.fields
            Row {
                id: embedFieldsRow
                property var _model: model

                width: parent.width
                spacing: Theme.paddingSmall

                Repeater {
                    id: embedFieldsRowRepeater
                    model: _model.row
                    Column {
                        width: (embedFieldsRow.width / embedFieldsRowRepeater.count) - embedFieldsRow.spacing*(embedFieldsRowRepeater.count-1)

                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: model.name
                            font.bold: true
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: model.value
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            }
        }

        EmbedImageText {
            property string footerText: shared.emojify(embed.footer.text)
            property string timestamptText: embed.timestamp > -1 ? Format.formatDate(new Date(embed.timestamp)) : ''
            text: footerText && timestamptText ? (footerText + '&nbsp;•&nbsp;' + timestamptText) : (footerText || timestamptText)
            icon.source: embed.footer.icon
            icon.visible: embed.footer.icon
            wrapMode: Text.Wrap
            truncationMode: TruncationMode.Elide
        }
    }
}
