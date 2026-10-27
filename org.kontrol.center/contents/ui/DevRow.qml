import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets

// One Bluetooth device in the list (connected or available), with an expandable detail part.
RowBox {
    id: dr
    property var ctl
    property var d
    signal toggleOpen()
    readonly property var th: ctl.theme
    function ic(f) { return ctl.iconBase + f }
    property bool open: false
    readonly property bool busy: ctl.btBusy[d.mac] === true
    theme: ctl.theme
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        spacing: 6
        Kirigami.Icon {
            Layout.preferredWidth: 20; Layout.preferredHeight: 20
            source: dr.ic(Presets.btIcon(dr.d.icon, dr.d.name)); isMask: true; color: dr.th.textOnOff
        }
        MarqueeText {
            Layout.fillWidth: true
            text: dr.d.name; color: dr.th.textOnOff; font.pixelSize: 14; font.bold: true
            forceHover: dr.hovered
        }
        Text {
            visible: dr.d.sig >= 0 && !dr.busy
            text: dr.d.sig + "%"; color: dr.th.textOnOff; font.pixelSize: 13
        }
        Text { visible: dr.busy; text: "..."; color: dr.th.textOnOff; font.pixelSize: 14; font.bold: true }
        // connected: red disconnect; available: connect
        IconBtn {
            visible: dr.d.connected; enabled: !dr.busy
            source: dr.ic("circle-x.svg"); filled: true
            tip: ctl.t("disconnect")
            onClicked: ctl.btDisconnect(dr.d.mac)
        }
        IconBtn {
            visible: !dr.d.connected; enabled: !dr.busy
            source: dr.ic("plug-connected.svg"); color: "#3fb950"
            tip: ctl.t("connect")
            onClicked: ctl.btConnect(dr.d.mac)
        }
        IconBtn {   // remove from trusted devices: only for connected devices
            visible: dr.d.connected; enabled: !dr.busy
            source: dr.ic("trash.svg"); color: dr.th.textOnOff
            tip: ctl.t("remove")
            onClicked: ctl.btRemove(dr.d.mac)
        }
        IconBtn {
            source: dr.ic(dr.open ? "chevron-up.svg" : "chevron-down.svg"); color: dr.th.textOnOff
            tip: ctl.t("details")
            onClicked: dr.toggleOpen()
        }
    }
    RowLayout {
        visible: dr.open
        Layout.fillWidth: true
        Text { text: ctl.t("auto_reconnect"); color: dr.th.textOnOff; font.pixelSize: 13; Layout.fillWidth: true }
        ToggleSwitch { theme: dr.th; small: true; checked: dr.d.trusted; onToggled: function(v) { ctl.btTrust(dr.d.mac, v) } }
    }
    RowLayout {
        visible: dr.open
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        Text { text: ctl.t("address"); color: dr.th.textOnOff; font.pixelSize: 13; Layout.fillWidth: true }
        Text { text: dr.d.mac; color: dr.th.textOnOff; font.pixelSize: 13 }
    }
}
