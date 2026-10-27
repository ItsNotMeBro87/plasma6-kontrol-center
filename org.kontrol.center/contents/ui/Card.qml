import QtQuick
import QtQuick.Layouts

// Rounded box (the big grey areas of the expansion pages). Its corners follow the button that opened the page.
Rectangle {
    id: card
    property var theme
    property string src: "large"
    property int pad: 14
    default property alias content: inner.data
    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 2 * pad
    radius: theme.cardRadius(src)
    color: theme.cardColor
    border.width: theme.btnBorderW
    border.color: theme.btnBorderCol
    ColumnLayout {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.pad
        spacing: 8
    }
}
