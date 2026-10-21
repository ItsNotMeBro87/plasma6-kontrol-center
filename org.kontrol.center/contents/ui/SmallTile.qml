import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Small button with a label below. Accent colour = on, grey = off. Mouse wheel emits wheelMoved(+1/-1).
Item {
    id: r
    property var theme
    property url iconSource
    property string label: ""
    property bool active: false
    signal clicked()
    signal wheelMoved(int dir)

    Layout.fillWidth: true
    Layout.preferredHeight: 78

    Rectangle {
        id: c
        width: 48; height: 48
        radius: r.theme.smallRadius
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property color baseColor: r.active ? r.theme.litColor : r.theme.offColor
        color: ma.pressed ? Qt.darker(baseColor, 1.1) : (ma.containsMouse ? Qt.lighter(baseColor, 1.07) : baseColor)
        Behavior on color { ColorAnimation { duration: 150 } }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24; height: 24
            source: r.iconSource
            isMask: true
            color: r.active ? r.theme.textOnOn : r.theme.textOnOff
        }
    }
    Text {
        anchors.top: c.bottom
        anchors.topMargin: 6
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: r.label
        color: r.theme.textOnPanel
        font.pixelSize: 12
        font.bold: true
        elide: Text.ElideRight
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: r.clicked()
        onWheel: function(w) {
            if (w.angleDelta.y !== 0) r.wheelMoved(w.angleDelta.y > 0 ? 1 : -1)
            w.accepted = true
        }
    }
}
