import QtQuick
import QtQuick.Layouts

// One list row (a network, a device ...). Click anywhere on it that is not a button -> activated().
Rectangle {
    id: rb
    property var theme
    property string src: "large"
    property bool clickable: false
    default property alias content: inner.data
    signal activated()
    readonly property bool hovered: bgHover.hovered
    HoverHandler { id: bgHover }
    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 8
    radius: theme.rowRadius(src, implicitHeight)
    readonly property color base: theme.rowColor
    color: (clickable && bg.containsMouse) ? Qt.lighter(base, 1.1) : base
    border.width: theme.btnBorderW
    border.color: theme.btnBorderCol
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: bg
        anchors.fill: parent
        hoverEnabled: true
        enabled: rb.clickable
        cursorShape: rb.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: rb.activated()
    }
    ColumnLayout {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        anchors.topMargin: 4
        spacing: 4
    }
}
