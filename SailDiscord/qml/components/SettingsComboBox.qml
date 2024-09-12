import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

// TODO
ComboBox {
    property var _values // {"author & time (default)": "d", "author": "a", "none": "n"}
    property string _title: ""
    property string _description: ""
    property var _option

    property var _keys: {
        var res = [];
        for (var key in _values) res.push(key)
        return res
    }

    label: _title
    description: _description
    currentIndex: values.indexOf(_option) == -1 ? 0 : values.indexOf(_option)
    menu: ContextMenu {
        Repeater {
            model: _keys
            MenuItem {
                text: _keys[index]
            }
        }
    }

    onCurrentItemChanged: {
        _option = _values[currentItem.text]
    }
}
