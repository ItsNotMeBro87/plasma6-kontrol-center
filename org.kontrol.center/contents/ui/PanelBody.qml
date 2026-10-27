import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets
import "Strings.js" as Strings

// The visible control center (at scale 100 %; Panel.qml scales it). Everything it shows comes from `ctl` (main.qml) and the saved settings.
//
//  - the header (date, uptime, session buttons) is always visible;
//  - below it is either the normal page (brightness / volume / large / small / media sections, listed in ctl.sections)
//    or one expansion page (Wi-Fi, Bluetooth, Picker, Sound) with its own bar (back button, name, extra controls);
//  - if the content is taller than the screen allows, the area below the header scrolls and two arrow notches appear
//    (one right under the header / page bar, one at the bottom).
Item {
    id: panel
    property var ctl
    readonly property var th: ctl.theme
    readonly property int gap: th.gap          // the ONE spacing used for padding and between all rows
    readonly property bool onMain: ctl.page === "main"
    readonly property int arrowH: 22

    implicitWidth: th.panelWidth
    readonly property real k: ctl.conf.panelScale / 100
    readonly property int barH: 38
    LayoutMirroring.enabled: Strings.rtl[ctl.conf.language] === true
    LayoutMirroring.childrenInherit: true

    // ---- vertical budget
    readonly property real barTop: gap + header.implicitHeight + gap                  // top of the page bar (expansion pages)
    readonly property real bodyTop: onMain ? barTop : barTop + pageBar.height + gap   // top of the scrolling area
    readonly property real avail: Math.max(120, ctl.maxPanelHeight / k - bodyTop - gap)   // room for the body (incl. arrows)
    // an expansion page is never smaller than the normal page (same total height), only bigger if it has more to show
    readonly property real mainWant: sectionsCol.implicitHeight
    readonly property real pageWant: pageLoader.item ? pageLoader.item.implicitHeight : 0
    readonly property real want: onMain ? mainWant : Math.max(pageWant, mainWant - barH - gap)
    readonly property bool overflow: want > avail
    readonly property real flickH: overflow ? avail - 2 * (arrowH + 6) : want
    implicitHeight: bodyTop + (overflow ? avail : want) + gap

    function ic(file) { return ctl.iconBase + file }
    function compFor(key) {
        var k = String(key).split("#")[0]
        if (k === "brightness") return brightnessComp
        if (k === "volume") return volumeComp
        if (k === "large") return largeComp
        if (k === "small") return smallComp
        if (k === "media") return mediaComp
        return null
    }

    // ---- panel background (optional shadow, border)
    Rectangle { id: bgSrc; anchors.fill: parent; radius: th.panelRadius; color: th.panel; layer.enabled: true; visible: false }
    MultiEffect {
        z: -1
        anchors.fill: bgSrc
        source: bgSrc
        visible: th.panelShadowOn
        shadowEnabled: th.panelShadowOn
        shadowColor: th.panelShadowCol
        shadowBlur: th.panelShadowBlur
        shadowOpacity: 0.8
        shadowVerticalOffset: 4
    }
    Rectangle {
        anchors.fill: parent
        radius: th.panelRadius
        color: th.panel
        border.width: th.panelBorderW
        border.color: th.panelBorderCol
    }

    // ================= Header: date + uptime (left), session icons (right) - always visible =================
    RowLayout {
        id: header
        x: gap; y: gap
        width: panel.width - 2 * gap
        spacing: 0
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            HaloText {
                theme: th
                visible: ctl.conf.showDate
                Layout.fillWidth: true
                text: ctl.uiLocale.toString(ctl.now, Presets.dateFormatOf(ctl.conf.dateFormat))
                color: th.textOnPanel
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }
            HaloText {
                theme: th
                visible: ctl.conf.showUptime
                Layout.fillWidth: true
                text: ctl.uptime !== "" ? ctl.t("uptime") + " " + ctl.uptime : ""
                color: th.textOnPanel
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: -5          // icon sits 5px inside its cell: line it up with the panel padding
            spacing: 0
            Repeater {
                model: [
                    { f: "lock.svg",             c: "loginctl lock-session" },
                    { f: "logout.svg",           c: "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout" },
                    { f: "rotate-clockwise.svg", c: "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot" },
                    { f: "power.svg",            c: "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutDown" }
                ]
                delegate: Item {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    HaloIcon {
                        theme: th
                        anchors.centerIn: parent
                        width: 24; height: 24
                        source: panel.ic(modelData.f)
                        color: th.textOnPanel
                        iconOpacity: hb.pressed ? 0.6 : (hb.containsMouse ? 1.0 : 0.85)
                    }
                    MouseArea {
                        id: hb
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ctl.closeAnd(modelData.c)
                    }
                }
            }
        }
    }

    // ================= Page bar (expansion pages only): back, name, extra controls =================
    Item {
        id: pageBar
        visible: !panel.onMain
        x: gap; y: panel.barTop
        width: panel.width - 2 * gap
        height: panel.onMain ? 0 : panel.barH
        readonly property string pg: ctl.page
        readonly property bool hasRefresh: pg === "wifi" || pg === "bluetooth"
        readonly property bool hasSwitch: pg === "wifi" || pg === "bluetooth"
        RowLayout {
            anchors.fill: parent
            spacing: 6
            Item {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                HaloIcon { theme: th; anchors.centerIn: parent; width: 26; height: 26; source: panel.ic("chevron-left.svg"); color: th.textOnPanel; iconOpacity: bk.containsMouse ? 1.0 : 0.9 }
                MouseArea {
                    id: bk
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: ctl.closePage()
                    QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("back"); QQC2.ToolTip.delay: 600
                }
            }
            HaloText {
                theme: th
                Layout.fillWidth: true
                text: pageBar.pg === "wifi" ? ctl.t("btn.wifi")
                    : (pageBar.pg === "bluetooth" ? ctl.t("btn.bluetooth")
                    : (pageBar.pg === "picker" ? ctl.t("picker_title") : ctl.t("sound_title")))
                color: th.textOnPanel
                font.pixelSize: 19
                font.bold: true
                elide: Text.ElideRight
            }
            Item {
                visible: pageBar.hasRefresh
                Layout.preferredWidth: 28; Layout.preferredHeight: 28
                HaloIcon {
                    id: rfIcon
                    theme: th; anchors.centerIn: parent; width: 17; height: 17
                    source: panel.ic("refresh.svg"); color: th.textOnPanel; iconOpacity: rf.containsMouse ? 1.0 : 0.85
                    // spins while a refresh is running; stops (after finishing the turn) when it is really done
                    SequentialAnimation on rotation {
                        running: ctl.refreshing
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { from: 0; to: 360; duration: 900 }
                    }
                }
                MouseArea {
                    id: rf
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (!ctl.refreshing) ctl.pageRefresh() }
                    QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("refresh"); QQC2.ToolTip.delay: 600
                }
            }
            ToggleSwitch {
                visible: pageBar.hasSwitch
                theme: th
                checked: pageBar.pg === "wifi" ? ctl.wifiOn : ctl.btOn
                onToggled: { if (pageBar.pg === "wifi") ctl.toggleWifi(); else ctl.toggleBluetooth() }
            }
            Rectangle {   // clear all colors (Picker page)
                visible: pageBar.pg === "picker"
                Layout.preferredWidth: 34; Layout.preferredHeight: 30
                radius: Math.min(th.rowRadius(ctl.pageSrc, 30), 8)
                color: cl.containsMouse ? "#ff3b36" : "#e5201e"
                opacity: ctl.pickerHistory.length > 0 ? 1 : 0.4
                Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: panel.ic("trash.svg"); isMask: true; color: "white" }
                MouseArea {
                    id: cl
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: ctl.pickerHistory.length > 0
                    onClicked: ctl.clearHistory()
                    QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("clear_all"); QQC2.ToolTip.delay: 600
                }
            }
        }
    }

    // ================= Scroll arrows (only when the content does not fit) =================
    Rectangle {
        id: upNotch
        visible: panel.overflow
        x: gap; y: panel.bodyTop
        width: panel.width - 2 * gap; height: panel.arrowH
        radius: Math.min(th.rowRadius("large", height), height / 2)
        color: upMa.containsMouse ? Qt.lighter(th.offColor, 1.15) : th.offColor
        opacity: flick.contentY > 1 ? 1.0 : 0.35
        border.width: th.btnBorderW; border.color: th.btnBorderCol
        Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: panel.ic("chevron-up.svg"); isMask: true; color: th.textOnOff }
        MouseArea {
            id: upMa
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: panel.scrollBy(-flick.height * 0.7)
            QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("scroll_up"); QQC2.ToolTip.delay: 700
        }
    }
    Rectangle {
        id: downNotch
        visible: panel.overflow
        x: gap; y: panel.bodyTop + panel.avail - panel.arrowH
        width: panel.width - 2 * gap; height: panel.arrowH
        radius: Math.min(th.rowRadius("large", height), height / 2)
        color: downMa.containsMouse ? Qt.lighter(th.offColor, 1.15) : th.offColor
        opacity: flick.contentY < flick.contentHeight - flick.height - 1 ? 1.0 : 0.35
        border.width: th.btnBorderW; border.color: th.btnBorderCol
        Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: panel.ic("chevron-down.svg"); isMask: true; color: th.textOnOff }
        MouseArea {
            id: downMa
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: panel.scrollBy(flick.height * 0.7)
            QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("scroll_down"); QQC2.ToolTip.delay: 700
        }
    }
    function scrollBy(d) {
        var max = Math.max(0, flick.contentHeight - flick.height)
        scrollAnim.to = Math.max(0, Math.min(max, flick.contentY + d))
        scrollAnim.restart()
    }
    NumberAnimation { id: scrollAnim; target: flick; property: "contentY"; duration: 180; easing.type: Easing.OutQuad }

    // ================= Body =================
    Flickable {
        id: flick
        x: gap
        y: panel.bodyTop + (panel.overflow ? panel.arrowH + 6 : 0)
        width: panel.width - 2 * gap
        height: panel.flickH
        contentWidth: width
        contentHeight: panel.want
        clip: panel.overflow
        interactive: panel.overflow
        boundsBehavior: Flickable.StopAtBounds
        onContentHeightChanged: if (contentY > Math.max(0, contentHeight - height)) contentY = Math.max(0, contentHeight - height)

        // ---- the normal page
        ColumnLayout {
            id: sectionsCol
            // kept alive (just invisible and inert) on other pages: its height is the size the pages must not fall below
            opacity: panel.onMain ? 1 : 0
            enabled: panel.onMain
            width: flick.width
            spacing: panel.gap
            Repeater {
                model: ctl.sections
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    visible: item ? item.shown : false
                    sourceComponent: panel.compFor(modelData)
                    onLoaded: item.key = modelData
                }
            }
        }

        // ---- an expansion page
        Loader {
            id: pageLoader
            visible: !panel.onMain
            width: flick.width
            sourceComponent: ctl.page === "wifi" ? wifiPageComp
                           : (ctl.page === "bluetooth" ? btPageComp
                           : (ctl.page === "picker" ? pickerPageComp
                           : (ctl.page === "sound" ? soundPageComp : null)))
        }
    }
    Connections { target: ctl; function onPageChanged() { flick.contentY = 0 } }

    Component { id: wifiPageComp;   WifiPage { ctl: panel.ctl } }
    Component { id: btPageComp;     BluetoothPage { ctl: panel.ctl } }
    Component { id: pickerPageComp; PickerPage { ctl: panel.ctl } }
    Component { id: soundPageComp;  SoundPage { ctl: panel.ctl } }

    // ---------------------------------------------------------------- Brightness (one bar per screen)
    Component {
        id: brightnessComp
        ColumnLayout {
            property string key: ""
            readonly property bool shown: ctl.displays.count > 0
            width: parent ? parent.width : 0
            spacing: panel.gap

            Repeater {
                model: ctl.displays
                delegate: CtrlSlider {
                    theme: th
                    step: ctl.conf.wheelBrightness / 100
                    iconSource: panel.ic(index === 0 ? "sun.svg" : "device-desktop.svg")
                    label: ctl.displays.count > 1 ? model.dlabel : ""
                    value: model.dvalue
                    onMoved: function(v) {
                        ctl.touch()
                        ctl.displays.setProperty(index, "dvalue", v)
                        var p = ctl.pendingDisp
                        p[model.dname] = Math.round(v * model.dmax)
                        ctl.pendingDisp = p
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- Volume (+ button that opens the Sound page)
    Component {
        id: volumeComp
        RowLayout {
            property string key: ""
            readonly property bool shown: true
            width: parent ? parent.width : 0
            spacing: panel.gap

            CtrlSlider {
                theme: th
                step: ctl.conf.wheelVolume / 100
                iconSource: panel.ic(ctl.muted ? "volume-off.svg" : "volume.svg")
                iconClickable: true
                value: ctl.muted ? 0 : ctl.volume
                onMoved: function(v) { ctl.touch(); ctl.pendingVol = v; ctl.volume = v; ctl.muted = false }
                onIconClicked: ctl.sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", 400)
            }
            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 42
                radius: th.sliderRadius
                property color b: th.offColor
                color: mb.pressed ? Qt.darker(b, 1.1) : (mb.containsMouse ? Qt.lighter(b, 1.07) : b)
                border.width: th.btnBorderW
                border.color: th.btnBorderCol
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 24; height: 24
                    source: panel.ic("adjustments-horizontal.svg")
                    isMask: true
                    color: th.textOnOff
                }
                MouseArea {
                    id: mb
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctl.openPage("sound", "slider")
                    QQC2.ToolTip.visible: containsMouse; QQC2.ToolTip.text: ctl.t("sound_settings"); QQC2.ToolTip.delay: 700
                }
            }
        }
    }

    // ---------------------------------------------------------------- Large buttons
    Component {
        id: largeComp
        GridLayout {
            id: lg
            property string key: ""
            readonly property var list: ctl.buttonsOf(key)
            readonly property bool shown: list.length > 0
            width: parent ? parent.width : 0
            columns: 2
            columnSpacing: panel.gap
            rowSpacing: panel.gap
            Repeater {
                model: lg.list
                delegate: LargeTile {
                    theme: th
                    label: ctl.labelOf(modelData)
                    sub: ctl.entrySub(modelData)
                    active: ctl.entryOn(modelData)
                    iconSource: ctl.entryIcon(modelData)
                    chevronSource: panel.ic("chevron-right.svg")
                    showChevron: ctl.hasChevron(modelData)
                    onClicked: ctl.entryClick(modelData)
                    onChevronClicked: ctl.entryChevron(modelData, "large")
                    onWheelMoved: function(dir) { ctl.entryWheel(modelData, dir) }
                }
            }
        }
    }

    // ---------------------------------------------------------------- Small buttons
    Component {
        id: smallComp
        GridLayout {
            id: sm
            property string key: ""
            readonly property var list: ctl.buttonsOf(key)
            readonly property bool shown: list.length > 0
            width: parent ? parent.width : 0
            columns: 6
            columnSpacing: 0
            rowSpacing: 0
            Repeater {
                model: sm.list
                delegate: SmallTile {
                    theme: th
                    label: ctl.labelOf(modelData)
                    active: ctl.entryOn(modelData)
                    iconSource: ctl.entryIcon(modelData)
                    showNotch: ctl.hasChevron(modelData)
                    onClicked: ctl.entryClick(modelData)
                    onNotchClicked: ctl.entryChevron(modelData, "small")
                    onWheelMoved: function(dir) { ctl.entryWheel(modelData, dir) }
                }
            }
        }
    }

    // ---------------------------------------------------------------- Media banner
    Component {
        id: mediaComp
        Rectangle {
            id: mediaCard
            property string key: ""
            readonly property bool live: ctl.mediaActive
            // hidden when nothing plays, unless "show when idle" is on in the settings
            readonly property bool shown: live || ctl.conf.mediaShowIdle
            width: parent ? parent.width : 0
            implicitHeight: 124
            radius: th.mediaRadius
            // "cover" mode: the card takes a calm, dark (or light) shade of the album cover's accent and the progress
            // bar a clearly lighter (or darker) shade of the same hue, so the two never melt together
            property real artH: 0
            property real artS: 0
            property bool artValid: false
            readonly property bool coverMode: (th.mediaMode === "coverDark" || th.mediaMode === "coverLight") && live && artValid
            readonly property bool darkTone: th.mediaMode !== "coverLight"
            readonly property color cardColor: coverMode
                ? Qt.hsla(artH, Math.min(0.55, artS * 0.6 + 0.08), darkTone ? 0.24 : 0.84, 1)
                : (th.mediaMode.indexOf("cover") === 0 ? th.offColor : th.mediaColor)
            readonly property color ink: th.inkFor(cardColor)
            readonly property color track: Qt.tint(cardColor, Qt.rgba(ink.r, ink.g, ink.b, 0.32))
            color: cardColor
            border.width: th.mediaBorderW
            border.color: th.mediaBorderCol
            property color artColor: th.litColor

            Rectangle { id: shSrc; anchors.fill: parent; radius: mediaCard.radius; color: mediaCard.cardColor; layer.enabled: true; visible: false }
            MultiEffect {
                z: -1
                anchors.fill: shSrc
                source: shSrc
                visible: th.mediaShadowOn
                shadowEnabled: th.mediaShadowOn
                shadowColor: th.mediaShadowCol
                shadowBlur: th.mediaShadowBlur
                shadowOpacity: 0.8
                shadowVerticalOffset: 3
            }

            // reads the album cover and picks its most vivid colour for the progress bar
            Canvas {
                id: sampler
                width: 24; height: 24
                opacity: 0
                property string src: mediaCard.live ? ctl.artUrl : ""
                onSrcChanged: {
                    if (src !== "") loadImage(src)
                    else { mediaCard.artColor = th.litColor; mediaCard.artValid = false }
                }
                onImageLoaded: requestPaint()
                onPaint: {
                    if (src === "" || !isImageLoaded(src)) return
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.drawImage(src, 0, 0, width, height)
                    var d = ctx.getImageData(0, 0, width, height).data
                    var ws = [0,0,0,0,0,0,0,0,0,0,0,0], rs = [0,0,0,0,0,0,0,0,0,0,0,0]
                    var gs = [0,0,0,0,0,0,0,0,0,0,0,0], bs = [0,0,0,0,0,0,0,0,0,0,0,0]
                    var ar = 0, ag = 0, ab = 0, an = 0
                    for (var i = 0; i < d.length; i += 4) {
                        var r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255
                        if (d[i + 3] < 128) continue
                        ar += r; ag += g; ab += b; an++
                        var mx = Math.max(r, g, b), mn = Math.min(r, g, b)
                        var s = mx === 0 ? 0 : (mx - mn) / mx
                        if (mx < 0.2 || s < 0.15) continue
                        var dl = mx - mn, h
                        if (mx === r) h = ((g - b) / dl) % 6
                        else if (mx === g) h = (b - r) / dl + 2
                        else h = (r - g) / dl + 4
                        h *= 60
                        if (h < 0) h += 360
                        var k = Math.floor(h / 30) % 12
                        var w = s * s * (0.3 + mx)
                        ws[k] += w; rs[k] += r * w; gs[k] += g * w; bs[k] += b * w
                    }
                    var best = 0
                    for (var j = 1; j < 12; j++) if (ws[j] > ws[best]) best = j
                    var cr, cg, cb
                    if (ws[best] > 0.05) { cr = rs[best] / ws[best]; cg = gs[best] / ws[best]; cb = bs[best] / ws[best] }
                    else if (an > 0) { cr = ar / an; cg = ag / an; cb = ab / an }
                    else { mediaCard.artColor = th.litColor; mediaCard.artValid = false; return }
                    var vivid = Qt.rgba(cr, cg, cb, 1)
                    mediaCard.artH = vivid.hslHue < 0 ? 0 : vivid.hslHue
                    mediaCard.artS = vivid.hslSaturation
                    mediaCard.artValid = true
                    var l = 0.299 * cr + 0.587 * cg + 0.114 * cb
                    if (th.lum(mediaCard.cardColor) > 0.5) {
                        if (l > 0.55) { var f = 0.55 / l; cr *= f; cg *= f; cb *= f }
                    } else if (l < 0.45) {
                        var t = (0.45 - l) / (1 - l); cr += (1 - cr) * t; cg += (1 - cg) * t; cb += (1 - cb) * t
                    }
                    mediaCard.artColor = Qt.rgba(cr, cg, cb, 1)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: panel.gap

                Item {   // cover art
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Layout.alignment: Qt.AlignVCenter
                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(th.mediaRadius, 10)
                        color: mediaCard.track
                        visible: !mediaCard.live || ctl.artUrl === ""
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 36; height: 36
                            source: panel.ic("music.svg")
                            isMask: true
                            color: mediaCard.cardColor
                        }
                    }
                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: mediaCard.live ? ctl.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        visible: false
                    }
                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: Math.min(th.mediaRadius, 10)
                        layer.enabled: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: artImg
                        maskEnabled: true
                        maskSource: artMask
                        visible: mediaCard.live && ctl.artUrl !== ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            MarqueeText {
                                text: mediaCard.live ? ctl.mediaTitle : ctl.t("nothing_playing")
                                color: mediaCard.ink
                                font.pixelSize: 18
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            MarqueeText {
                                text: mediaCard.live ? ctl.mediaArtist : ctl.t("idle")
                                color: mediaCard.ink
                                opacity: mediaCard.live ? 1 : 0.7
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            MarqueeText {
                                text: mediaCard.live ? [ctl.mediaAlbum, ctl.mediaYear].filter(function(x) { return x !== "" }).join(" - ") : ""
                                color: mediaCard.ink
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                        RowLayout {
                            spacing: 4
                            opacity: mediaCard.live ? 1 : 0.4
                            Repeater {
                                model: [
                                    { k: "prev", c: "previous" },
                                    { k: "play", c: "play-pause" },
                                    { k: "next", c: "next" }
                                ]
                                delegate: Rectangle {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: (mm.containsMouse && mediaCard.live) ? Qt.lighter(mediaCard.cardColor, 1.15) : "transparent"
                                    border.width: 2
                                    border.color: mediaCard.ink
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: 15; height: 15
                                        source: modelData.k === "play"
                                                ? panel.ic(ctl.mediaStatus === "Playing" ? "player-pause.svg" : "player-play.svg")
                                                : panel.ic(modelData.k === "prev" ? "player-skip-back.svg" : "player-skip-forward.svg")
                                        isMask: true
                                        color: mediaCard.ink
                                    }
                                    MouseArea {
                                        id: mm
                                        anchors.fill: parent
                                        enabled: mediaCard.live
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ctl.mpris(modelData.c)
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: mediaCard.live ? ctl.fmt(ctl.mediaPos) : "0:00"
                            color: mediaCard.ink
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Text {
                            text: mediaCard.live ? ctl.fmt(ctl.mediaLen) : "0:00"
                            color: mediaCard.ink
                            font.pixelSize: 12
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 6
                            radius: 3
                            color: mediaCard.track
                            Rectangle {
                                width: (mediaCard.live && ctl.mediaLen > 0) ? parent.width * Math.min(1, ctl.mediaPos / ctl.mediaLen) : 0
                                height: parent.height
                                radius: 3
                                color: mediaCard.artColor
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: mediaCard.live
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(m) {
                                if (ctl.mediaLen > 0) {
                                    var sec = Math.round(m.x / width * ctl.mediaLen)
                                    ctl.mediaPos = sec
                                    ctl.mpris("position " + sec)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
