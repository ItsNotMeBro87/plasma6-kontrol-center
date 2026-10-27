import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Small round icon button with a tooltip (used in the Wi-Fi / Bluetooth / Sound lists).
Item {
    id: b
    property url source
    property color color: "white"
    property string tip: ""
    property int iconSize: 18
    property bool filled: false          // a colored disc behind the icon (e.g. the red disconnect button)
    property color fillColor: "#e5201e"
    signal clicked()
    implicitWidth: 28
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.centerIn: parent
        width: 26; height: 26; radius: 13
        color: b.filled ? b.fillColor : b.color
        opacity: b.filled ? 1.0 : (ma.pressed ? 0.22 : (ma.containsMouse ? 0.12 : 0))
    }
    Kirigami.Icon {
        anchors.centerIn: parent
        width: b.iconSize; height: b.iconSize
        source: b.source
        isMask: true
        color: b.filled ? "white" : b.color
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
        QQC2.ToolTip.visible: containsMouse && b.tip !== ""
        QQC2.ToolTip.text: b.tip
        QQC2.ToolTip.delay: 500
    }
}
