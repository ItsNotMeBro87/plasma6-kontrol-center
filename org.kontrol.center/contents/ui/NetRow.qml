import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// One Wi-Fi network in the list (saved or available).
RowBox {
    id: nr
    property var ctl
    property var n
    readonly property var th: ctl.theme
    function ic(f) { return ctl.iconBase + f }
    theme: ctl.theme
    clickable: !n.active
    onActivated: ctl.wifiPick(n)
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        spacing: 8
        MarqueeText {
            Layout.fillWidth: true
            text: nr.n.ssid
            color: nr.th.textOnOff; font.pixelSize: 14; font.bold: true
            forceHover: nr.hovered
        }
        Kirigami.Icon {
            Layout.preferredWidth: 16; Layout.preferredHeight: 16
            source: nr.ic(nr.n.secure ? "lock.svg" : "lock-open.svg")
            isMask: true; color: nr.th.textOnOff; opacity: 0.85
        }
        Text {
            Layout.preferredWidth: 42
            horizontalAlignment: Text.AlignRight
            text: ctl.wifiBusySsid === nr.n.ssid ? "..." : (nr.n.signal >= 0 ? nr.n.signal + "%" : "\u2014")
            color: nr.th.textOnOff; font.pixelSize: 13
        }
        // current network: check mark; saved network: trash (forget); available network: nothing
        Item {
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            Kirigami.Icon {
                anchors.centerIn: parent; width: 18; height: 18
                visible: nr.n.active
                source: nr.ic("check.svg"); isMask: true; color: nr.th.textOnOff
            }
            IconBtn {
                anchors.centerIn: parent
                visible: nr.n.saved && !nr.n.active
                source: nr.ic("trash.svg"); color: nr.th.textOnOff
                tip: ctl.t("forget")
                onClicked: ctl.wifiForget(nr.n.ssid)
            }
        }
    }
}
