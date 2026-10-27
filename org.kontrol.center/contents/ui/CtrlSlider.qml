import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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
    property color trackColor: theme.offColor
    readonly property real shown: dragging ? dragValue : value
    signal moved(real v)
    signal iconClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 42
    radius: theme.sliderRadius
    color: trackColor

    // optional shadow (drawn behind the bar)
    Rectangle { id: shSrc; anchors.fill: parent; radius: s.radius; color: s.trackColor; layer.enabled: true; visible: false }
    MultiEffect {
        z: -1
        anchors.fill: shSrc
        source: shSrc
        visible: s.theme.btnShadowOn
        shadowEnabled: s.theme.btnShadowOn
        shadowColor: s.theme.btnShadowCol
        shadowBlur: s.theme.btnShadowBlur
        shadowOpacity: 0.75
        shadowVerticalOffset: 2
    }

    Rectangle {
        visible: s.shown > 0
        width: Math.min(s.width, Math.max(s.height, s.width * s.shown))
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
    Rectangle {   // border on top, so it is not hidden by the filled part
        anchors.fill: parent
        radius: s.radius
        color: "transparent"
        border.width: s.theme.btnBorderW
        border.color: s.theme.btnBorderCol
        visible: s.theme.btnBorderW > 0
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true     // a scrolling panel must not take over a slider drag
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
        onCanceled: s.dragging = false
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
