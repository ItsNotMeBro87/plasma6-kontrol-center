import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Large button (WiFi, Bluetooth, Pen Display, Power Profile ...). Mouse wheel emits wheelMoved(+1/-1).
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
    Behavior on color { ColorAnimation { duration: 150 } }

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
            Text {
                text: w.label
                color: w.inkColor
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                visible: w.sub !== ""
                text: w.sub
                color: w.inkColor
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        Kirigami.Icon {
            visible: w.showChevron
            source: w.chevronSource
            isMask: true
            color: w.inkColor
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
    MouseArea {   // arrow zone
        visible: w.showChevron
        width: 46
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        onClicked: w.chevronClicked()
    }
}
