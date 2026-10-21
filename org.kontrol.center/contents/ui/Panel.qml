import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets

// The visible control center. Everything it shows comes from `ctl` (main.qml) and the saved settings.
// Sections (brightness / volume / large buttons / small buttons / media banner) are listed in ctl.sections
// and can be reordered, removed and repeated as often as you like from the settings.
Item {
    id: panel
    property var ctl
    readonly property var th: ctl.theme
    readonly property int gap: th.gap          // the ONE spacing used for padding and between all rows

    implicitWidth: 420
    implicitHeight: col.implicitHeight + 2 * gap

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

    Rectangle {
        anchors.fill: parent
        radius: th.panelRadius
        color: th.panel
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: panel.gap
        spacing: panel.gap

        // ================= Header: date + uptime (left), session icons (right) =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                Text {
                    visible: ctl.conf.showDate
                    Layout.fillWidth: true
                    text: Qt.locale().toString(ctl.now, Presets.dateFormatOf(ctl.conf.dateFormat))
                    color: th.textOnPanel
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    visible: ctl.conf.showUptime
                    Layout.fillWidth: true
                    text: ctl.uptime !== "" ? "Uptime: " + ctl.uptime : ""
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
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 24; height: 24
                            source: panel.ic(modelData.f)
                            isMask: true
                            color: th.textOnPanel
                            opacity: hb.pressed ? 0.6 : (hb.containsMouse ? 1.0 : 0.85)
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

        // ================= Sections, in the order chosen in the settings =================
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

    // ---------------------------------------------------------------- Volume (+ shortcut to sound settings)
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
                    onClicked: ctl.closeAnd("systemsettings kcm_pulseaudio")
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
                    label: Presets.labelOf(modelData)
                    sub: ctl.entrySub(modelData)
                    active: ctl.entryOn(modelData)
                    iconSource: ctl.entryIcon(modelData)
                    chevronSource: panel.ic("chevron-right.svg")
                    showChevron: ctl.hasChevron(modelData)
                    onClicked: ctl.entryClick(modelData)
                    onChevronClicked: ctl.entryChevron(modelData)
                    onWheelMoved: function(dir) { ctl.entryWheel(modelData, dir) }
                }
            }
        }
    }

    // ---------------------------------------------------------------- Small buttons (+ colour picker history)
    Component {
        id: smallComp
        ColumnLayout {
            id: sm
            property string key: ""
            readonly property var list: ctl.buttonsOf(key)
            readonly property bool shown: list.length > 0
            readonly property bool hasPicker: list.some(function(b) { return b.preset === "picker" })
            width: parent ? parent.width : 0
            spacing: panel.gap

            GridLayout {
                Layout.fillWidth: true
                columns: 6
                columnSpacing: 0
                rowSpacing: 0
                Repeater {
                    model: sm.list
                    delegate: SmallTile {
                        theme: th
                        label: Presets.labelOf(modelData)
                        active: ctl.entryOn(modelData)
                        iconSource: ctl.entryIcon(modelData)
                        onClicked: ctl.entryClick(modelData)
                        onWheelMoved: function(dir) { ctl.entryWheel(modelData, dir) }
                    }
                }
            }

            // recent colours: one slim row under the buttons; click a colour to copy its hex code
            RowLayout {
                Layout.fillWidth: true
                visible: sm.hasPicker && ctl.pickerHistory.length > 0
                spacing: 6
                Text {
                    text: ctl.copiedHex !== "" ? "Copied" : "Recent"
                    color: th.textOnPanel
                    opacity: 0.75
                    font.pixelSize: 11
                    font.bold: true
                    Layout.rightMargin: 2
                }
                Repeater {
                    model: ctl.pickerHistory.slice(0, 7)
                    delegate: Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: Math.min(6, th.smallRadius)
                        color: modelData
                        border.width: ctl.copiedHex === modelData ? 2 : 1
                        border.color: ctl.copiedHex === modelData ? th.textOnPanel : Qt.rgba(th.textOnPanel.r, th.textOnPanel.g, th.textOnPanel.b, 0.35)
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: ctl.copyColor(modelData)
                            QQC2.ToolTip.visible: containsMouse
                            QQC2.ToolTip.text: modelData + " (click to copy)"
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: ctl.copiedHex
                    color: th.textOnPanel
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "Clear"
                    color: th.textOnPanel
                    opacity: clrMa.containsMouse ? 1 : 0.6
                    font.pixelSize: 11
                    MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ctl.clearHistory() }
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
            color: th.mediaColor
            property color artColor: th.litColor

            // reads the album cover and picks its most vivid colour for the progress bar
            Canvas {
                id: sampler
                width: 24; height: 24
                opacity: 0
                property string src: mediaCard.live ? ctl.artUrl : ""
                onSrcChanged: {
                    if (src !== "") loadImage(src)
                    else mediaCard.artColor = th.litColor
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
                    else { mediaCard.artColor = th.litColor; return }
                    var l = 0.299 * cr + 0.587 * cg + 0.114 * cb
                    if (th.lum(th.mediaColor) > 0.5) {
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
                        color: th.mediaTrack
                        visible: !mediaCard.live || ctl.artUrl === ""
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 36; height: 36
                            source: panel.ic("music.svg")
                            isMask: true
                            color: th.mediaColor
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
                            Text {
                                text: mediaCard.live ? ctl.mediaTitle : "Nothing playing"
                                color: th.textOnMedia
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: mediaCard.live ? ctl.mediaArtist : "Idle"
                                color: th.textOnMedia
                                opacity: mediaCard.live ? 1 : 0.7
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: mediaCard.live ? [ctl.mediaAlbum, ctl.mediaYear].filter(function(x) { return x !== "" }).join(" - ") : ""
                                color: th.textOnMedia
                                font.pixelSize: 12
                                elide: Text.ElideRight
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
                                    color: (mm.containsMouse && mediaCard.live) ? Qt.lighter(th.mediaColor, 1.15) : "transparent"
                                    border.width: 2
                                    border.color: th.textOnMedia
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: 15; height: 15
                                        source: modelData.k === "play"
                                                ? panel.ic(ctl.mediaStatus === "Playing" ? "player-pause.svg" : "player-play.svg")
                                                : panel.ic(modelData.k === "prev" ? "player-skip-back.svg" : "player-skip-forward.svg")
                                        isMask: true
                                        color: th.textOnMedia
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
                            color: th.textOnMedia
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Text {
                            text: mediaCard.live ? ctl.fmt(ctl.mediaLen) : "0:00"
                            color: th.textOnMedia
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
                            color: th.mediaTrack
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
