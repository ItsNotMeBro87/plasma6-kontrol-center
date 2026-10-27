import QtQuick

// Pill button with text; `outlined` draws a border (the main action), otherwise it is plain text.
Rectangle {
    id: tb
    property var theme
    property string text: ""
    property bool outlined: false
    property bool enabledBtn: true
    signal clicked()
    implicitWidth: lbl.implicitWidth + 28
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    radius: Math.min(theme.largeRadius, height / 2)
    color: ma.pressed ? Qt.rgba(1, 1, 1, 0.22) : (ma.containsMouse && enabledBtn ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
    border.width: outlined ? 1 : 0
    border.color: theme.textOnOff
    opacity: enabledBtn ? 1 : 0.4
    Text {
        id: lbl
        anchors.centerIn: parent
        text: tb.text
        color: tb.theme.textOnOff
        font.pixelSize: 13
        font.bold: true
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: tb.enabledBtn
        cursorShape: Qt.PointingHandCursor
        onClicked: tb.clicked()
    }
}
