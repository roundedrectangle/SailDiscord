import QtQuick 2.0
import Sailfish.Silica 1.0

MenuItem {
    id: menuItem
    layer.onEffectChanged: if (layer.effect) layer.effect = rampComponent

    Component {
        id: rampComponent
        OpacityRampEffectBase {
            id: rampEffect
            direction: horizontalAlignment == Text.AlignRight ? OpacityRamp.RightToLeft
                                                              : OpacityRamp.LeftToRight
            source: menuItem
            slope: Math.max(
                       1 + 6 * menuItem.width / Screen.width,
                       menuItem.width / Math.max(1, 2 * (menuItem.implicitWidth - width)))
            offset: 1 - 1 / slope

            property bool down: menuItem.down
            onDownChanged: menuItem.down = down
            Connections {
                target: menuItem
                onDownChanged: rampEffect.down = menuItem.down
            }
            signal clicked
            onClicked: menuItem.clicked()
        }
    }
}
