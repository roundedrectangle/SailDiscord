/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2016,2019  Sander van Grieken

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: menuRow

    width: menu.width
    spacing: 0

    property bool __opal__fancy_menus__fancy_menu_row: true

    property var checkIconOnly: function() { return false }
    property var checkShort: function() { return false }

    function _checkIconOnly(size) { return checkIconOnly(sizedCount / size, size) }
    function _checkShort(size) { return checkShort(sizedCount / size, size) }

    property Item menu: parent.parent // FancyContextMenu/FancyPullDownMenu
    property Item menuContainer: parent
    property bool isPulley: menu && (typeof menu._isPullDownMenu !== 'undefined')
    property real xPos: width / 2 // the x position we need to track

    property int count: visibleChildren.length
    property real sizedCount: {
        var result = 0
        for (var i=0; i < count; i++) {
            var item = menuRow.visibleChildren[i]
            if (item && item.size) // needed for Repeater
                result += item.size
        }
        return result
    }

    property real itemWidth: (width - spacing*(count-1)) / Math.max(sizedCount, 0) // calculated item width, equally divided

    // these get fed from ContextMenu/PullDownMenu
    property bool down
    property bool highlighted
    property bool _invertColors

    signal clicked
    signal earlyClick
    signal delayedClick

    // Pulley menus don't feed the down property
    // we still do this to items inside the row just in case
    property bool selected: isPulley ? highlighted : down

    // magic needed so jolla's contextmenu recognizes the Row as a menuitem
    property int __silica_menuitem

    // current highlighted item
    property Item _highlightedItem

    property bool enabled: !_highlightedItem || _highlightedItem.enabled // makes the menu know if the item is enabled (only makes visual improvemenyd)

    function updateHighlightbarFor(item) {
        menu._highlightBar.x = item ? item.x : menuContainer.x
        menu._highlightBar.width = item && item.enabled && item.highlight ? item.width : 0
    }

    function resetHighlightbar() {
        menu._highlightBar.x = 0 //menuContainer.x // or simply 0? pulleyMenu/*(parent here)*/.x breaks landscape in FancyPullDownMenu
        menu._highlightBar.width = menu.width
    }

    function resetXPos() {
        xPos = width / 2
    }

    // TODO: pulley menus: shared XPos when switching stuff

    // first xpos change event is received _after_ we receive the events from
    // the contextmenu, so this is for initialising xpos in those cases.
    function updateXPosFromMenu() {
        if (isPulley) return // TODO

        if (menu.listItem/* && settings.commentsTapToHide*/) { // if listItem is set, events are produced relative listItem
            xPos = menu._contentColumn.mapFromItem(menu.listItem, menu.listItem.mouseX, menu.listItem.mouseY).x
        } else {
            xPos = menu._contentColumn.mapFromItem(menu, menu.mouseX, menu.mouseY).x
        }
    }

    onXPosChanged: {
        if (!selected) return

        if (xPos < 0) xPos = 0
        if (xPos > width) xPos = width

        var item = childAt(xPos, 0);
        if (item !== _highlightedItem) {
            if (_highlightedItem)
                _highlightedItem.down = false
            _highlightedItem = item
            if (_highlightedItem)
                _highlightedItem.down = down
            updateHighlightbarFor(item)
        }
    }

    onSelectedChanged: {
        if (selected) {
            updateXPosFromMenu()
            var item = childAt(xPos, 0)
            _highlightedItem = item
            if (_highlightedItem)
                _highlightedItem.down = true
            updateHighlightbarFor(item)
        } else {
            resetXPos()
            resetHighlightbar();
            if (_highlightedItem)
                _highlightedItem.down = false
            _highlightedItem = null
        }
    }

    onClicked: {
        updateXPosFromMenu();
        var item = childAt(xPos, 0);
        if (item)
            if (item.enabled)
                item.clicked();
            // else: prevent menu from being closed, because the Row is always enabled
    }
}
