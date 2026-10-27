import QtQuick

// On / off switch in the widget's colors.
Item {
    id: sw
    property var theme
    property bool checked: false
    property bool small: false
    signal toggled(bool value)
    implicitWidth: small ? 34 : 40
    implicitHeight: small ? 19 : 22
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? sw.theme.litColor : Qt.tint(sw.theme.offColor, Qt.rgba(sw.theme.textOnOff.r, sw.theme.textOnOff.g, sw.theme.textOnOff.b, 0.18))
        border.width: sw.theme.btnBorderW
        border.color: sw.theme.btnBorderCol
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            width: parent.height - 5
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2.5 : 2.5
            color: sw.checked ? sw.theme.textOnOn : sw.theme.textOnOff
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
