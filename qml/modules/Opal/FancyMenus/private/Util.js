function findHighlightRectangle(item) {
    // find highlight rectangle
    for (var i=0; i<item.data.length; i++) {
        var childItem = item.data[i]
        if (childItem.hasOwnProperty("highlightedItem"))
            // got the highlightbar
            return childItem
    }
    console.log("HighlightBar not found!")
}

function childAt(parent, x, y) {
    var child = parent.childAt(x, y)
    if (child && child.hasOwnProperty("fragmentShader") && child.source && child.source.layer.effect) {
        // This item is a layer effect of the actual item.
        child = child.source
    }

    return child
}
