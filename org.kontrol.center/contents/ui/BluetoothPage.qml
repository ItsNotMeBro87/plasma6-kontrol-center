import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets

// Bluetooth expansion page: discoverable switch, pairing request, connected + available devices.
ColumnLayout {
    id: pg
    property var ctl
    readonly property var th: ctl.theme
    readonly property string src: ctl.pageSrc
    property var openMap: ({})
    width: parent ? parent.width : 0
    spacing: th.gap

    function ic(f) { return ctl.iconBase + f }
    function toggleOpen(mac) { var m = {}; for (var k in openMap) m[k] = openMap[k]; if (m[mac]) delete m[mac]; else m[mac] = true; openMap = m }
    readonly property var connList: ctl.btDevices.filter(function(d) { return d.connected })
    readonly property var availList: ctl.btDevices.filter(function(d) { return !d.connected })
    readonly property bool usable: ctl.btOn && !ctl.btMissing

    // ---- discoverable
    RowLayout {
        Layout.fillWidth: true
        visible: pg.usable
        spacing: 8
        HaloText { theme: pg.th; Layout.fillWidth: true; text: ctl.t("discoverable"); color: th.textOnPanel; font.pixelSize: 17 }
        ToggleSwitch { theme: pg.th; checked: ctl.btDiscoverable; onToggled: function(v) { ctl.btSetDiscoverable(v) } }
    }

    // ---- pairing request
    Card {
        theme: pg.th; src: pg.src
        visible: ctl.btRequest !== null && pg.usable
        Text { text: ctl.t("pair_title", { name: ctl.btRequest ? ctl.btRequest.name : "" }); color: th.textOnOff; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
        Text {
            text: {
                var r = ctl.btRequest
                if (!r) return ""
                if (r.kind === "confirm") return ctl.t("confirm_code")
                if (r.kind === "authorize") return ctl.t("authorize_msg", { name: r.name })
                if (r.kind === "show") return ctl.t("show_code", { name: r.name })
                return ctl.t("enter_pin", { name: r.name })
            }
            color: th.textOnOff; font.pixelSize: 13; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Text {
            visible: ctl.btRequest !== null && (ctl.btRequest.kind === "confirm" || ctl.btRequest.kind === "show") && ctl.btRequest.code !== ""
            text: ctl.btRequest ? ctl.btRequest.code : ""
            color: th.litColor; font.pixelSize: 24; font.bold: true; font.letterSpacing: 3
        }
        Rectangle {
            id: pinBox
            visible: ctl.btRequest !== null && (ctl.btRequest.kind === "pin" || ctl.btRequest.kind === "passkey")
            Layout.fillWidth: true; Layout.preferredHeight: 36
            radius: th.rowRadius(pg.src, 36)
            color: Qt.darker(th.cardColor, 1.25)
            border.width: 1; border.color: pinInput.activeFocus ? th.litColor : Qt.rgba(th.textOnOff.r, th.textOnOff.g, th.textOnOff.b, 0.55)
            TextInput {
                id: pinInput
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: th.textOnOff; font.pixelSize: 15; clip: true
                onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                onAccepted: ctl.btAnswer(true, text)
            }
        }
        RowLayout {
            spacing: 6
            TextBtn {
                theme: pg.th; outlined: true
                visible: ctl.btRequest !== null && ctl.btRequest.kind !== "show"
                text: ctl.t("accept")
                onClicked: ctl.btAnswer(true, pinInput.text)
            }
            TextBtn {
                theme: pg.th
                visible: ctl.btRequest !== null && ctl.btRequest.kind !== "show"
                text: ctl.t("reject")
                onClicked: ctl.btAnswer(false, "")
            }
            TextBtn {
                theme: pg.th
                visible: ctl.btRequest !== null && ctl.btRequest.kind === "show"
                text: ctl.t("cancel")
                onClicked: ctl.btAnswer(false, "")
            }
        }
    }

    // ---- devices
    Card {
        theme: pg.th; src: pg.src
        Text { visible: ctl.btMissing; text: ctl.t("bt_missing"); color: th.textOnOff; font.pixelSize: 14; font.bold: true }
        Text { visible: !ctl.btMissing && !ctl.btOn; text: ctl.t("bt_off"); color: th.textOnOff; font.pixelSize: 14; font.bold: true }
        Text {
            visible: pg.usable && ctl.btDevices.length === 0
            text: ctl.t("no_devices"); color: th.textOnOff; opacity: 0.8; font.pixelSize: 13
            wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Text { visible: pg.usable && pg.connList.length > 0; text: ctl.t("connected_h"); color: th.textOnOff; font.pixelSize: 16; font.bold: true }
        Repeater { model: pg.usable ? pg.connList : []; delegate: DevRow { ctl: pg.ctl; src: pg.src; d: modelData; open: pg.openMap[modelData.mac] === true; onToggleOpen: pg.toggleOpen(modelData.mac) } }
        Text { visible: pg.usable && pg.availList.length > 0; text: ctl.t("available_h"); color: th.textOnOff; font.pixelSize: 16; font.bold: true; Layout.topMargin: 4 }
        Repeater { model: pg.usable ? pg.availList : []; delegate: DevRow { ctl: pg.ctl; src: pg.src; d: modelData; open: pg.openMap[modelData.mac] === true; onToggleOpen: pg.toggleOpen(modelData.mac) } }
    }
}
