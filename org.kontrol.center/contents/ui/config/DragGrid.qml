import QtQuick
import org.kde.kirigami as Kirigami

// A grid of cells you can drag and drop to reorder. Dropping a cell on another cell INSERTS it there
// and shifts everything in between (left->right, top->bottom), exactly like moving an item in a list.
// Click a cell (without dragging) to select it.
Item {
    id: g
    property var model              // ListModel
    property int columns: 2
    property real cellW: 120
    property real cellH: 52
    property real gap: 6
    property int selected: -1
    property int dropIndex: -1
    property int dragFrom: -1
    property string dragLabel: ""
    property var labelFn: null      // function(modelRow) -> string
    property var iconFn: null       // function(modelRow) -> icon source
    signal move(int from, int to)
    signal pick(int index)

    readonly property int count: model ? model.count : 0
    readonly property int rows: Math.max(1, Math.ceil(count / columns))
    implicitWidth: columns * cellW + (columns - 1) * gap
    implicitHeight: rows * cellH + (rows - 1) * gap
    width: implicitWidth
    height: implicitHeight

    Grid {
        id: grid
        columns: g.columns
        spacing: g.gap
        Repeater {
            model: g.model
            delegate: Rectangle {
                id: cell
                property int cellIndex: index
                width: g.cellW
                height: g.cellH
                radius: 6
                color: g.dragFrom === index ? Qt.rgba(0.5, 0.5, 0.5, 0.15) : Kirigami.Theme.alternateBackgroundColor
                border.width: (g.dropIndex === index && g.dragFrom !== index) ? 3 : (g.selected === index ? 2 : 1)
                border.color: (g.dropIndex === index && g.dragFrom !== index) || g.selected === index
                              ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 20; height: 20
                        source: g.iconFn ? g.iconFn(model) : ""
                        visible: source.toString() !== ""
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }
                    Text {
                        width: g.cellW - 8
                        horizontalAlignment: Text.AlignHCenter
                        text: g.labelFn ? g.labelFn(model) : ""
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true   // the settings page scrolls vertically; without this it steals up/down drags
                    property bool dragging: false
                    property real px: 0
                    property real py: 0
                    onPressed: function(m) { px = m.x; py = m.y; dragging = false }
                    onPositionChanged: function(m) {
                        if (!pressed) return
                        if (!dragging && (Math.abs(m.x - px) + Math.abs(m.y - py)) > 10) {
                            dragging = true
                            g.dragFrom = cell.cellIndex
                            g.dragLabel = g.labelFn ? g.labelFn(g.model.get(cell.cellIndex)) : ""
                        }
                        if (dragging) {
                            var p = ma.mapToItem(g, m.x, m.y)
                            ghost.x = p.x - ghost.width / 2
                            ghost.y = p.y - ghost.height / 2
                            var q = ma.mapToItem(grid, m.x, m.y)
                            var it = grid.childAt(q.x, q.y)
                            g.dropIndex = (it && it.cellIndex !== undefined) ? it.cellIndex : -1
                        }
                    }
                    onReleased: function(m) {
                        if (dragging) {
                            var from = g.dragFrom, to = g.dropIndex
                            g.dragFrom = -1
                            g.dropIndex = -1
                            dragging = false
                            if (from >= 0 && to >= 0 && to !== from) g.move(from, to)
                        } else {
                            g.pick(cell.cellIndex)
                        }
                    }
                    onCanceled: { dragging = false; g.dragFrom = -1; g.dropIndex = -1 }
                }
            }
        }
    }

    Rectangle {   // the cell you are carrying
        id: ghost
        visible: g.dragFrom >= 0
        z: 100
        width: g.cellW
        height: g.cellH
        radius: 6
        opacity: 0.9
        color: Kirigami.Theme.highlightColor
        Text {
            anchors.centerIn: parent
            width: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: g.dragLabel
            color: Kirigami.Theme.highlightedTextColor
            font.pixelSize: 12
            font.bold: true
        }
    }
}
