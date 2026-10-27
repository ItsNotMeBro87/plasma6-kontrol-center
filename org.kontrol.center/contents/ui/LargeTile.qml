import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// Large button (Wi-Fi, Bluetooth, Pen Display, Power Profile ...). Mouse wheel emits wheelMoved(+1/-1).
// Buttons with a page of their own (Wi-Fi, Bluetooth, Picker) show an arrow on the right: the arrow zone and the
// rest of the button are two separate click areas.
Rectangle {
    id: w
    property var theme
    property url iconSource
    property url chevronSource
    property string label: ""
    property string sub: ""
    property bool active: false
    property bool showChevron: false
    signal clicked()
    signal chevronClicked()
    signal wheelMoved(int dir)

    Layout.fillWidth: true
    Layout.preferredWidth: 1     // equal column widths whatever the label length
    Layout.preferredHeight: 54
    radius: theme.largeRadius
    readonly property color baseColor: active ? theme.litColor : theme.offColor
    readonly property color inkColor: active ? theme.textOnOn : theme.textOnOff
    color: main.pressed ? Qt.darker(baseColor, 1.08) : (main.containsMouse ? Qt.lighter(baseColor, 1.07) : baseColor)
    border.width: theme.btnBorderW
    border.color: theme.btnBorderCol
    Behavior on color { ColorAnimation { duration: 150 } }

    // optional shadow (drawn behind the button)
    Rectangle { id: shSrc; anchors.fill: parent; radius: w.radius; color: w.baseColor; layer.enabled: true; visible: false }
    MultiEffect {
        z: -1
        anchors.fill: shSrc
        source: shSrc
        visible: w.theme.btnShadowOn
        shadowEnabled: w.theme.btnShadowOn
        shadowColor: w.theme.btnShadowCol
        shadowBlur: w.theme.btnShadowBlur
        shadowOpacity: 0.75
        shadowVerticalOffset: 2
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12
        Kirigami.Icon {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            source: w.iconSource
            isMask: true
            color: w.inkColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            MarqueeText {
                text: w.label
                color: w.inkColor
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
                forceHover: main.containsMouse
            }
            MarqueeText {
                visible: w.sub !== ""
                text: w.sub
                color: w.inkColor
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
                forceHover: main.containsMouse
            }
        }
        Kirigami.Icon {
            visible: w.showChevron
            source: w.chevronSource
            isMask: true
            color: w.inkColor
            opacity: zone.containsMouse ? 1.0 : 0.8
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }
    }
    MouseArea {
        id: main
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: w.clicked()
        onWheel: function(wh) {
            if (wh.angleDelta.y !== 0) w.wheelMoved(wh.angleDelta.y > 0 ? 1 : -1)
            wh.accepted = true
        }
    }
    MouseArea {   // arrow zone: opens the page (sits on top of the main area, so a click lands in exactly one of them)
        id: zone
        visible: w.showChevron
        width: 46
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: w.chevronClicked()
    }
}
