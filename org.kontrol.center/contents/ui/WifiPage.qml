import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Wi-Fi expansion page: current connection, password prompt, saved + available networks.
ColumnLayout {
    id: pg
    property var ctl
    readonly property var th: ctl.theme
    readonly property string src: ctl.pageSrc
    readonly property var cur: ctl.wifiCurrent
    property bool showPw: false
    width: parent ? parent.width : 0
    spacing: th.gap

    function ic(f) { return ctl.iconBase + f }

    readonly property var savedList: ctl.wifiNets.filter(function(n) { return n.saved })
    readonly property var availList: ctl.wifiNets.filter(function(n) { return !n.saved })

    // ---- current connection (only when connected)
    Card {
        theme: pg.th; src: pg.src
        visible: pg.cur !== null && ctl.wifiOn
        Text { text: ctl.t("current_connection"); color: th.textOnOff; font.pixelSize: 16; font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            MarqueeText {
                text: pg.cur ? pg.cur.ssid : ""
                color: th.textOnOff; font.pixelSize: 14; font.bold: true
                Layout.maximumWidth: pg.width * 0.4
            }
            MarqueeText {
                Layout.fillWidth: true
                text: pg.cur ? [ctl.wifiIp, pg.cur.signal + "%", pg.cur.band].filter(function(x) { return x !== "" && x !== undefined }).join("  \u2022  ") : ""
                color: th.textOnOff; opacity: 0.85; font.pixelSize: 12
            }
            IconBtn {
                source: pg.ic("circle-x.svg"); filled: true
                tip: ctl.t("disconnect")
                onClicked: ctl.wifiDisconnect()
            }
        }
    }

    // ---- password prompt (a new network that needs one)
    Card {
        id: pwCard
        theme: pg.th; src: pg.src
        visible: ctl.wifiPrompt !== ""
        onVisibleChanged: if (visible) { pwInput.text = ""; pg.showPw = false; pwInput.forceActiveFocus() }
        Text { text: ctl.t("enter_password", { ssid: ctl.wifiPrompt }); color: th.textOnOff; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: th.rowRadius(pg.src, 38)
                color: Qt.darker(th.cardColor, 1.25)
                border.width: 1
                border.color: pwInput.activeFocus ? th.litColor : Qt.rgba(th.textOnOff.r, th.textOnOff.g, th.textOnOff.b, 0.55)
                TextInput {
                    id: pwInput
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: th.textOnOff
                    selectionColor: th.litColor
                    selectedTextColor: th.textOnOn
                    font.pixelSize: 14
                    clip: true
                    echoMode: pg.showPw ? TextInput.Normal : TextInput.Password
                    onAccepted: if (text !== "") ctl.wifiConnect(ctl.wifiPrompt, text)
                    Text {
                        visible: pwInput.text === ""
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: ctl.t("password"); color: th.textOnOff; opacity: 0.6; font.pixelSize: 14
                    }
                }
            }
            IconBtn {
                source: pg.ic(pg.showPw ? "eye-off.svg" : "eye.svg"); color: th.textOnOff; iconSize: 22
                tip: ctl.t("show_password")
                onClicked: pg.showPw = !pg.showPw
            }
        }
        Text { visible: ctl.wifiMsg !== ""; text: ctl.wifiMsg; color: "#ff7b72"; font.pixelSize: 12; font.bold: true; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            spacing: 6
            TextBtn {
                theme: pg.th; outlined: true
                text: ctl.wifiBusySsid !== "" ? ctl.t("connecting") : ctl.t("connect")
                enabledBtn: pwInput.text !== "" && ctl.wifiBusySsid === ""
                onClicked: ctl.wifiConnect(ctl.wifiPrompt, pwInput.text)
            }
            TextBtn { theme: pg.th; text: ctl.t("cancel"); onClicked: { ctl.wifiPrompt = ""; ctl.wifiMsg = "" } }
        }
    }

    // message outside the prompt (company networks, a failed connection to a saved network)
    Text {
        visible: ctl.wifiPrompt === "" && ctl.wifiMsg !== ""
        text: ctl.wifiMsg
        color: th.textOnPanel; font.pixelSize: 12; font.bold: true
        wrapMode: Text.WordWrap; Layout.fillWidth: true
    }

    // ---- saved + available
    Card {
        theme: pg.th; src: pg.src
        Text {
            visible: !ctl.wifiOn
            text: ctl.t("wifi_off"); color: th.textOnOff; font.pixelSize: 14; font.bold: true
        }
        Text {
            visible: ctl.wifiOn && ctl.wifiNets.length === 0
            text: ctl.t("no_networks"); color: th.textOnOff; opacity: 0.8; font.pixelSize: 13
            wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Text { visible: ctl.wifiOn && pg.savedList.length > 0; text: ctl.t("saved"); color: th.textOnOff; font.pixelSize: 16; font.bold: true }
        Repeater {
            model: ctl.wifiOn ? pg.savedList : []
            delegate: NetRow { ctl: pg.ctl; src: pg.src; n: modelData }
        }
        Text { visible: ctl.wifiOn && pg.availList.length > 0; text: ctl.t("available"); color: th.textOnOff; font.pixelSize: 16; font.bold: true; Layout.topMargin: 4 }
        Repeater {
            model: ctl.wifiOn ? pg.availList : []
            delegate: NetRow { ctl: pg.ctl; src: pg.src; n: modelData }
        }
    }
}
