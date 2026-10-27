import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// Small button with a label below. Accent colour = on, grey = off. Mouse wheel emits wheelMoved(+1/-1).
// Buttons with a page of their own (Wi-Fi, Bluetooth, Picker) carry a small round "arrow badge" on the bottom right
// corner. The badge has its own colour (a lighter / darker shade of the Off colour, it never lights up with the
// button) and a thin ring in the panel colour, so it stays visible on round buttons, boxy buttons, on and off.
// Clicks are split by position: inside the badge circle -> notchClicked(), everywhere else -> clicked().
Item {
    id: r
    property var theme
    property url iconSource
    property string label: ""
    property bool active: false
    property bool showNotch: false
    signal clicked()
    signal notchClicked()
    signal wheelMoved(int dir)

    readonly property int badgeD: 20            // badge diameter
    property bool overNotch: false

    Layout.fillWidth: true
    Layout.preferredHeight: 78

    Rectangle {
        id: c
        width: 48; height: 48
        radius: r.theme.smallRadius
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property color baseColor: r.active ? r.theme.litColor : r.theme.offColor
        color: (ma.pressed && !r.overNotch) ? Qt.darker(baseColor, 1.1) : ((ma.containsMouse && !r.overNotch) ? Qt.lighter(baseColor, 1.07) : baseColor)
        border.width: r.theme.btnBorderW
        border.color: r.theme.btnBorderCol
        Behavior on color { ColorAnimation { duration: 150 } }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24; height: 24
            source: r.iconSource
            isMask: true
            color: r.active ? r.theme.textOnOn : r.theme.textOnOff
        }
    }
    // optional shadow (drawn behind the button)
    Rectangle { id: shSrc; width: 48; height: 48; radius: c.radius; color: c.baseColor; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; layer.enabled: true; visible: false }
    MultiEffect {
        z: -1
        anchors.fill: shSrc
        source: shSrc
        visible: r.theme.btnShadowOn
        shadowEnabled: r.theme.btnShadowOn
        shadowColor: r.theme.btnShadowCol
        shadowBlur: r.theme.btnShadowBlur
        shadowOpacity: 0.75
        shadowVerticalOffset: 2
    }
    // the arrow badge, centred 5px inside the bottom right corner of the 48 x 48 button
    Rectangle {
        id: badge
        visible: r.showNotch
        width: r.badgeD; height: r.badgeD; radius: r.badgeD / 2
        x: c.x + c.width - 5 - r.badgeD / 2
        y: c.y + c.height - 5 - r.badgeD / 2
        z: 2
        readonly property color ink: r.theme.textOnOff
        color: Qt.tint(r.theme.offColor, Qt.rgba(ink.r, ink.g, ink.b, r.overNotch ? 0.55 : 0.38))
        border.width: 2
        border.color: r.theme.panelBase
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 10; height: 10
            rotation: 45                      // the right-pointing chevron now points to the bottom right
            source: Qt.resolvedUrl("../icons/chevron-right.svg")
            isMask: true
            color: badge.ink
        }
    }
    MarqueeText {
        anchors.top: c.bottom
        anchors.topMargin: 6
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: r.label
        color: r.theme.textOnPanel
        font.pixelSize: 12
        font.bold: true
        style: r.theme.legible ? Text.Outline : Text.Normal
        styleColor: r.theme.haloColor
        forceHover: ma.containsMouse
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // is this point inside the badge circle?
        function inNotch(mx, my) {
            if (!r.showNotch) return false
            var cx = badge.x + badge.width / 2, cy = badge.y + badge.height / 2
            var dx = mx - cx, dy = my - cy
            return dx * dx + dy * dy <= (r.badgeD / 2 + 1) * (r.badgeD / 2 + 1)
        }
        onPositionChanged: function(m) { r.overNotch = inNotch(m.x, m.y) }
        onExited: r.overNotch = false
        onClicked: function(m) {
            if (inNotch(m.x, m.y)) r.notchClicked()
            else r.clicked()
        }
        onWheel: function(w) {
            if (w.angleDelta.y !== 0) r.wheelMoved(w.angleDelta.y > 0 ? 1 : -1)
            w.accepted = true
        }
    }
}
