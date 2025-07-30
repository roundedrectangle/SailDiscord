import QtQuick 2.0
import Sailfish.Silica 1.0

Flickable {
    id: flickable
    readonly property bool fadeRight: (contentWidth-contentX) > width
    readonly property bool fadeLeft: !fadeRight && contentX > 0
    layer.enabled: fadeRight || fadeLeft
    layer.effect: OpacityRampEffectBase {
        direction: flickable.fadeRight ? OpacityRamp.LeftToRight : OpacityRamp.RightToLeft
        source: flickable
        slope: 1 + 6 * width / Screen.width
        offset: 1 - 1 / slope
    }
}
