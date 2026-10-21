import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Slider bar: click or drag to set, mouse wheel to nudge. At 0 the filled bar disappears completely.
Rectangle {
    id: s
    property var theme
    property real value: 0
    property real step: 0.05
    property url iconSource
    property string label: ""
    property bool iconClickable: false
    property bool dragging: false
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : value
    signal moved(real v)
    signal iconClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 42
    radius: theme.sliderRadius
    color: theme.offColor
    clip: true

    Rectangle {
        visible: s.shown > 0
        width: Math.max(s.height, s.width * s.shown)
        height: s.height
        radius: s.radius
        color: s.theme.litColor
    }
    Kirigami.Icon {
        source: s.iconSource
        isMask: true
        color: s.shown > 0 ? s.theme.textOnOn : s.theme.textOnOff
        width: 22; height: 22
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        visible: s.label !== ""
        text: s.label
        color: s.theme.textOnOff
        opacity: 0.8
        font.pixelSize: 11
        font.bold: true
        elide: Text.ElideRight
        width: Math.min(implicitWidth, s.width * 0.45)
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            var v = Math.max(0, Math.min(1, mx / s.width))
            if (v < 0.01) v = 0
            s.dragValue = v
            s.moved(v)
        }
        onPressed: function(m) {
            if (s.iconClickable && m.x < 46) { s.iconClicked(); return }
            s.dragging = true
            update(m.x)
        }
        onPositionChanged: function(m) { if (s.dragging) update(m.x) }
        onReleased: s.dragging = false
        onWheel: function(w) {
            var dir = w.angleDelta.y > 0 ? 1 : (w.angleDelta.y < 0 ? -1 : 0)
            if (dir !== 0) {
                var v = Math.max(0, Math.min(1, Math.round((s.shown + dir * s.step) * 100) / 100))
                s.moved(v)
            }
            w.accepted = true
        }
    }
}
