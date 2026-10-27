import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Sound expansion page. Hardware tab: playback devices (default device, ports, volume). Applications tab: volume per application.
ColumnLayout {
    id: pg
    property var ctl
    readonly property var th: ctl.theme
    readonly property string src: ctl.pageSrc
    width: parent ? parent.width : 0
    spacing: th.gap

    function ic(f) { return ctl.iconBase + f }

    // ---- tabs
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [ { id: "hardware", key: "hardware" }, { id: "apps", key: "applications" } ]
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 36
                readonly property bool sel: ctl.soundTab === modelData.id
                radius: th.rowRadius(pg.src, 36)
                color: sel ? th.litColor : (tma.containsMouse ? Qt.lighter(th.offColor, 1.1) : th.offColor)
                border.width: th.btnBorderW
                border.color: th.btnBorderCol
                Text { anchors.centerIn: parent; text: ctl.t(modelData.key); color: parent.sel ? th.textOnOn : th.textOnOff; font.pixelSize: 14; font.bold: true }
                MouseArea { id: tma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ctl.soundTab = modelData.id }
            }
        }
    }

    // ---- hardware
    Card {
        theme: pg.th; src: pg.src
        visible: ctl.soundTab === "hardware"
        Text { text: ctl.t("playback_devices"); color: th.textOnOff; font.pixelSize: 16; font.bold: true }
        Text { visible: ctl.audioSinks.length === 0; text: ctl.t("no_outputs"); color: th.textOnOff; opacity: 0.8; font.pixelSize: 13 }
        Repeater {
            model: ctl.audioSinks
            delegate: RowBox {
                id: sr
                readonly property var sk: modelData
                property real localVol: -1      // what the user just set; shown at once, the real value arrives with the next refresh
                theme: pg.th; src: pg.src
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 8
                    Item {   // radio: the default device
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        Rectangle {
                            anchors.centerIn: parent; width: 18; height: 18; radius: 9
                            color: "transparent"; border.width: 2; border.color: th.textOnOff
                            Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: th.litColor; visible: sr.sk.isDefault }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !sr.sk.isDefault; onClicked: ctl.setDefaultSink(sr.sk.name) }
                    }
                    MarqueeText { Layout.fillWidth: true; text: sr.sk.desc; color: th.textOnOff; font.pixelSize: 14; font.bold: true; forceHover: sr.hovered }
                    IconBtn {
                        source: pg.ic(sr.sk.muted ? "volume-off.svg" : "volume.svg"); color: th.textOnOff
                        tip: sr.sk.muted ? ctl.t("unmute") : ctl.t("mute")
                        onClicked: ctl.toggleSinkMute(sr.sk.name)
                    }
                }
                CtrlSlider {
                    theme: pg.th
                    trackColor: th.cardColor
                    Layout.preferredHeight: 32
                    step: ctl.conf.wheelVolume / 100
                    iconSource: pg.ic(sr.sk.muted ? "volume-off.svg" : "volume.svg")
                    label: Math.round((sr.localVol >= 0 ? sr.localVol : sr.sk.vol) * 100) + "%"
                    value: sr.localVol >= 0 ? sr.localVol : (sr.sk.muted ? 0 : sr.sk.vol)
                    onMoved: function(v) { sr.localVol = v; ctl.setSinkVol(sr.sk.name, v) }
                }
                // ports (e.g. line out on the back panel / headset on the front panel)
                Flow {
                    visible: sr.sk.ports.length > 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    Layout.bottomMargin: 4
                    spacing: 6
                    Text { text: ctl.t("port") + ":"; color: th.textOnOff; opacity: 0.85; font.pixelSize: 12; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater {
                        model: sr.sk.ports
                        delegate: Rectangle {
                            readonly property bool cur: modelData.name === sr.sk.port
                            height: 26; width: pl.implicitWidth + 20
                            radius: Math.min(th.rowRadius(pg.src, 26), 13)
                            color: cur ? th.litColor : (pma.containsMouse ? Qt.lighter(th.cardColor, 1.2) : th.cardColor)
                            Text { id: pl; anchors.centerIn: parent; text: modelData.desc; color: parent.cur ? th.textOnOn : th.textOnOff; font.pixelSize: 12; font.bold: true }
                            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ctl.setSinkPort(sr.sk.name, modelData.name) }
                        }
                    }
                }
            }
        }
    }

    // ---- applications
    Card {
        theme: pg.th; src: pg.src
        visible: ctl.soundTab === "apps"
        Text { visible: ctl.audioApps.length === 0; text: ctl.t("no_apps"); color: th.textOnOff; opacity: 0.85; font.pixelSize: 13; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Repeater {
            model: ctl.audioApps
            delegate: RowBox {
                id: ar
                readonly property var ap: modelData
                property real localVol: -1
                theme: pg.th; src: pg.src
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    spacing: 8
                    Kirigami.Icon {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        source: ar.ap.icon; fallback: "application-x-executable"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        MarqueeText { Layout.fillWidth: true; text: ar.ap.name; color: th.textOnOff; font.pixelSize: 14; font.bold: true; forceHover: ar.hovered }
                        MarqueeText { visible: ar.ap.sub !== ""; Layout.fillWidth: true; text: ar.ap.sub; color: th.textOnOff; opacity: 0.75; font.pixelSize: 11; forceHover: ar.hovered }
                    }
                    IconBtn {
                        source: pg.ic(ar.ap.muted ? "volume-off.svg" : "volume.svg"); color: th.textOnOff
                        tip: ar.ap.muted ? ctl.t("unmute") : ctl.t("mute")
                        onClicked: ctl.toggleAppMute(ar.ap.idx)
                    }
                }
                CtrlSlider {
                    theme: pg.th
                    trackColor: th.cardColor
                    Layout.preferredHeight: 32
                    Layout.bottomMargin: 2
                    step: ctl.conf.wheelVolume / 100
                    iconSource: pg.ic(ar.ap.muted ? "volume-off.svg" : "volume.svg")
                    label: Math.round((ar.localVol >= 0 ? ar.localVol : ar.ap.vol) * 100) + "%"
                    value: ar.localVol >= 0 ? ar.localVol : (ar.ap.muted ? 0 : ar.ap.vol)
                    onMoved: function(v) { ar.localVol = v; ctl.setAppVol(ar.ap.idx, v) }
                }
            }
        }
    }
}
