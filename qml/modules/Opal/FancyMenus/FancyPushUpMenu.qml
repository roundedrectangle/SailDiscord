import QtQuick 2.0
import Sailfish.Silica 1.0
import 'private/Util.js' as Util

PushUpMenu {
    id: pulleyMenu
    property Item _highlightBar
    property real _oldContentX

    Component.onCompleted: _highlightBar = Util.findHighlightRectangle(pulleyMenu)

    /* Important info about pulley menus:
    We use the same approach pulley menu uses to track opening. First, we enable dragging over bounds. Then, we track where the content moves and based on this move the selection.
    This has an issue, because at every start of a movement we think that it was started (horizontally) from the center of the screen. Without workarounds we would think that it is started from 0 (or last position).
    Fixing this would probably require a completely different approach.

    Also TODO: having both pulldownmenu and pushupmenu does not work currently.
    */

    property var __b1: Binding {
            target: flickable
            property: "flickableDirection"
            value: Flickable.HorizontalAndVerticalFlick
        }
    property var __b2: Binding {
        target: flickable
        property: "boundsBehavior"
        value: flickable.atYBeginning || flickable.contentY <= 0 ? Flickable.DragOverBounds : Flickable.StopAtBounds
    }

    // contentItem.opacityChanged does not seem to work, so we reset it when required automatically

    property var __c1: Connections {
        target: flickable

        onContentXChanged: {
            if (flickable.contentX == 0) return
            if (menuItem && menuItem.hasOwnProperty("xPos"))
                menuItem.xPos += (_oldContentX - flickable.contentX) * 2
            _oldContentX = flickable.contentX
            flickable.contentX = 0
        }
        onMovementEnded:  _oldContentX = 0

        onContentYChanged: {
            if (flickable.contentY - _finalPosition > 0) { // > 1.0
                flickable.contentY = _finalPosition
                flickable.contentItem.opacity = 1
            }
        }
    }

    onPositionChanged: {
        // propagate x-position since jolla's contextmenu doesn't remember it.
        if (menuItem && menuItem.hasOwnProperty("xPos")) {
            menuItem.xPos = _contentColumn.mapFromItem(pulleyMenu, mouse.x, mouse.y).x;
        }
    }
}
