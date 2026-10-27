import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Picker expansion page: every color picked so far (newest first, at most 20). Click = copy the hex code.
ColumnLayout {
    id: pg
    property var ctl
    readonly property var th: ctl.theme
    readonly property string src: ctl.pageSrc
    width: parent ? parent.width : 0
    spacing: th.gap

    function ic(f) { return ctl.iconBase + f }

    Card {
        id: card
        theme: pg.th; src: pg.src
        pad: 10
        readonly property int cols: Math.max(2, Math.floor((pg.width - 2 * pad + 6) / 90))
        readonly property real cellW: (pg.width - 2 * pad - (cols - 1) * 6) / cols

        Text {
            visible: ctl.pickerHistory.length === 0
            text: ctl.t("picker_empty"); color: th.textOnOff; font.pixelSize: 13
            wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.margins: 4
        }
        Text {
            visible: ctl.pickerHistory.length > 0
            text: ctl.t("picker_hint"); color: th.textOnOff; opacity: 0.8; font.pixelSize: 12
            Layout.leftMargin: 2
        }
        GridLayout {
            Layout.fillWidth: true
            columns: card.cols
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
                model: ctl.pickerHistory
                delegate: Rectangle {
                    id: sw
                    readonly property string hex: modelData
                    Layout.preferredWidth: card.cellW
                    Layout.preferredHeight: 72
                    radius: Math.min(th.cardRadius(pg.src), 10)
                    color: hex
                    border.width: 1
                    border.color: ctl.copiedHex === hex ? th.textOnOff : Qt.rgba(1, 1, 1, 0.35)
                    Rectangle {   // hex label strip
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 22
                        radius: parent.radius
                        color: Qt.rgba(0, 0, 0, 0.55)
                        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: parent.radius; color: parent.color }
                        Text {
                            anchors.centerIn: parent
                            text: ctl.copiedHex === sw.hex ? ctl.t("copied") : sw.hex
                            color: "white"; font.pixelSize: 11; font.bold: true
                        }
                    }
                    MouseArea {
                        id: cma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ctl.copyColor(sw.hex)
                    }
                    Rectangle {   // delete this color (appears on hover)
                        visible: cma.containsMouse || dma.containsMouse
                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4
                        width: 24; height: 24; radius: Math.min(6, th.cardRadius(pg.src))
                        color: dma.containsMouse ? "#e5201e" : Qt.rgba(0, 0, 0, 0.6)
                        Kirigami.Icon { anchors.centerIn: parent; width: 16; height: 16; source: pg.ic("trash.svg"); isMask: true; color: "white" }
                        MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ctl.removeHistory(sw.hex) }
                    }
                }
            }
        }
    }
}
