import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import QtGraphicalEffects 1.0

Item {
    id: controls
    property Video video

    property bool isPlaying: video.playbackState === MediaPlayer.PlayingState

    property bool active: true
    opacity: active ? 1 : 0
    Behavior on opacity { FadeAnimator {} }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered:
            if (isPlaying)
                controls.active = false
    }

    Connections {
        target: video
        onPlaying: hideTimer.start()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: active = !active
    }

    LinearGradient {
        width: parent.width
        anchors {
            top: slider.top
            bottom: parent.bottom
            topMargin: -Theme.itemSizeMedium
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: 'transparent' }
            GradientStop { position: 1.0; color: Theme.darkPrimaryColor }
        }
    }

    IconButton {
        anchors.centerIn: parent
        enabled: active
        icon.source: "image://theme/icon-l-"+(isPlaying ? 'pause' : 'play')
        onClicked:
            if (isPlaying) video.pause()
            else video.play()
    }

    Slider {
        id: slider
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium
        width: parent.width
        leftMargin: 0
        rightMargin: 0

        value: video.position
        minimumValue: 0
        maximumValue: video.duration || 0.1
        handleVisible: false
        animateValue: true
        stepSize: 500
        valueText: value > 0 || down ? Format.formatDuration(value/1000) : ''
        enabled: active

        onDownChanged: {
            if (!down) {
                video.seek(value)
                value = Qt.binding(function() { return video.position })
            }
        }
    }

    Label {
        anchors {
            right: parent.right
            rightMargin: Theme.paddingSmall
            bottom: parent.bottom
            topMargin: Theme.paddingSmall
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        property int duration: (slider.maximumValue - slider.value) / 1000
        text: duration > 0 ? Format.formatDuration(duration) : ''
    }
}
