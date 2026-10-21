import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation

    readonly property var conf: Plasmoid.configuration
    // read the real colour scheme (not the Plasma theme) so the panel can follow light/dark mode
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    readonly property color sysBg: Kirigami.Theme.backgroundColor
    readonly property color sysText: Kirigami.Theme.textColor
    readonly property color sysHighlight: Kirigami.Theme.highlightColor

    property alias theme: themeObj
    Theme {
        id: themeObj
        conf: root.conf
        systemAccent: root.accentHex
        sysBg: root.schemeBg !== "" ? root.schemeBg : root.sysBg
        sysText: root.schemeFg !== "" ? root.schemeFg : root.sysText
        sysHighlight: root.sysHighlight
    }

    // load state once at start so the very first popup already has its final size
    Component.onCompleted: { refresh(); refreshDisplays(); refreshColors() }

    readonly property int plasmoidLocation: Plasmoid.location
    readonly property string iconBase: Qt.resolvedUrl("../icons/").toString()
    readonly property string scriptDir: decodeURIComponent(Qt.resolvedUrl("../scripts/").toString().replace("file://", ""))
    function script(name, args) { return "bash '" + scriptDir + name + "'" + (args ? " " + args : "") }

    // ---------------- Settings-derived data ----------------
    function parseJson(s, fallback) { try { return JSON.parse(s) } catch (e) { return fallback } }
    readonly property var buttons: {
        var a = parseJson(conf.buttonsJson, null)
        if (!Array.isArray(a)) a = parseJson(Presets.defaultButtonsJson, [])
        return a
    }
    // buttons that belong to one layout group ("large", "small", "large#2", ...)
    function buttonsOf(g) {
        return buttons.filter(function(b) {
            if (b.preset === "mic" && !micPresent) return false       // no microphone connected: no mic button
            return (b.group || (b.size === "large" ? "large" : "small")) === g
        })
    }
    // the sections shown in the panel, top to bottom. A section that is not listed is removed.
    // (older versions had one combined "sliders" part; it becomes a brightness part + a volume part)
    readonly property var sections: {
        var out = []
        conf.sectionOrder.split(",").forEach(function(x) {
            x = x.trim()
            if (x === "") return
            if (x === "sliders") {
                ["brightness", "volume"].forEach(function(k) { if (out.indexOf(k) < 0) out.push(k) })
                return
            }
            out.push(x)
        })
        return out
    }
    readonly property var customStates: { var o = parseJson(conf.customStates, {}); return (o && typeof o === "object") ? o : {} }
    readonly property var pickerHistory: { var a = parseJson(conf.pickerHistory, []); return Array.isArray(a) ? a : [] }
    function penOutput() {
        for (var i = 0; i < buttons.length; i++) if (buttons[i].preset === "pen" && buttons[i].arg) return buttons[i].arg
        return "HDMI-A-1"
    }

    // widget icon on the panel
    readonly property bool panelIconIsFile: conf.panelIcon.indexOf("/") === 0 || conf.panelIcon.indexOf(".svg") > 0
    readonly property var panelIconSource: Presets.iconUrl(conf.panelIcon, iconBase) || (iconBase + "kc-gear.svg")
    Plasmoid.icon: panelIconIsFile ? "preferences-system" : panelIconSource
    toolTipMainText: "Kontrol Center"

    // ---------------- State ----------------
    property date now: new Date()
    property string uptime: ""
    property string accentHex: ""
    property string schemeBg: ""   // window background of the ACTIVE colour scheme (changes with dark/light mode)
    property string schemeFg: ""
    property bool wifiOn: false
    property bool wifiConn: false
    property string wifiSsid: ""
    property bool btOn: false
    property bool btConn: false
    property int btCount: 0
    property bool micPresent: false
    property bool micMuted: false
    property real volume: 0
    property bool muted: false
    property bool penOn: false
    property bool headphoneOn: false
    property bool caffeine: false
    property bool dnd: false
    property bool night: false
    property bool dark: false
    property bool airplane: false
    property bool warp: false
    property string profile: "balanced"
    property string copiedHex: ""
    property string player: ""
    property string mediaStatus: ""
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaAlbum: ""
    property string mediaYear: ""
    property string artUrl: ""
    property real mediaPos: 0
    property real mediaLen: 0
    readonly property bool mediaActive: (mediaStatus === "Playing" || mediaStatus === "Paused") && mediaTitle !== ""

    property real pendingVol: -1
    property var pendingDisp: ({})
    property double lastTouch: 0
    function isTouching() { return (Date.now() - lastTouch) < 1500 }
    function touch() { lastTouch = Date.now() }

    property alias displays: dispModel
    ListModel { id: dispModel }   // one row per screen: dname, dlabel, dmax, dvalue

    readonly property var profiles: ["power-saver", "balanced", "performance"]
    function fmt(sec) {
        var s = Math.max(0, Math.floor(sec))
        var m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }
    function profileName(p) { return p === "power-saver" ? "Power Saver" : (p === "performance" ? "Performance" : "Balanced") }
    function rgbToHex(s) {
        var p = (s || "").split(",")
        if (p.length < 3) return ""
        var h = ""
        for (var i = 0; i < 3; i++) {
            var n = parseInt(p[i])
            if (isNaN(n)) return ""
            n = Math.max(0, Math.min(255, n))
            h += (n < 16 ? "0" : "") + n.toString(16)
        }
        return "#" + h
    }

    // ---------------- Shell command runner ----------------
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        property var cbs: ({})
        onNewData: function(source, data) {
            exec.disconnectSource(source)
            var cb = cbs[source]
            delete cbs[source]
            if (cb) cb((data["stdout"] || "").trim())
        }
        function run(cmd, cb) {
            if (cb) cbs[cmd] = cb
            connectSource(cmd)
        }
    }

    // ---------------- Status ----------------
    function applyDisplays(lines) {
        var items = lines.map(function(l) {
            var p = l.split("|")
            return { dname: p[0], dlabel: p[1] || p[0], dcur: parseInt(p[2]) || 0, dmax: Math.max(1, parseInt(p[3]) || 100) }
        })
        var same = (items.length === dispModel.count)
        for (var i = 0; same && i < items.length; i++)
            if (dispModel.get(i).dname !== items[i].dname) same = false
        if (!same) {
            dispModel.clear()
            items.forEach(function(it) {
                dispModel.append({ dname: it.dname, dlabel: it.dlabel, dmax: it.dmax, dvalue: it.dcur / it.dmax })
            })
        } else if (!isTouching()) {
            items.forEach(function(it, idx) { dispModel.setProperty(idx, "dvalue", it.dcur / it.dmax) })
        }
    }

    function applyStatus(txt) {
        var o = {}
        txt.split("\n").forEach(function(l) {
            var i = l.indexOf("=")
            if (i <= 0) return
            o[l.substring(0, i)] = l.substring(i + 1)
        })
        now = new Date()
        uptime = o.uptime || ""
        accentHex = rgbToHex(o.accent)
        wifiOn = (o.wifi === "enabled")
        wifiConn = (o.wificonn === "1")
        wifiSsid = o.ssid || ""
        btOn = (o.bt === "on")
        btConn = (o.btconn === "1")
        btCount = parseInt(o.btcount) || 0
        micPresent = (o.mic === "1")
        micMuted = (o.micmuted === "1")
        if (o.vol && !isTouching()) volume = parseFloat(o.vol)
        muted = (o.muted === "1")
        penOn = (o.pen === "1")
        headphoneOn = (o.headphone === "1")
        caffeine = (o.caffeine === "1")
        dnd = (o.dnd === "1")
        night = (o.night === "true")
        dark = (o.dark === "1")
        airplane = (o.airplane === "1")
        warp = (o.warp === "1")
        if (o.profile) profile = o.profile

        player = o.player || ""
        var m = (o.media || "").split("|||")
        mediaStatus = m[0] || ""
        mediaArtist = m[1] || ""
        mediaTitle = m[2] || ""
        mediaAlbum = m[3] || ""
        mediaYear = (m[4] || "").substring(0, 4)
        artUrl = m[5] || ""
        mediaPos = (parseFloat(m[6]) || 0) / 1000000
        mediaLen = (parseFloat(m[7]) || 0) / 1000000
    }

    function refresh() {
        exec.run("timeout 12 " + script("status.sh", "'" + conf.mprisMatch + "' '" + penOutput() + "'"), applyStatus)
    }
    function refreshColors() {
        exec.run("kreadconfig6 --file kdeglobals --group Colors:Window --key BackgroundNormal; kreadconfig6 --file kdeglobals --group Colors:Window --key ForegroundNormal", function(txt) {
            var l = txt.split("\n")
            schemeBg = rgbToHex(l[0] || "")
            schemeFg = rgbToHex(l[1] || "")
        })
    }
    function refreshDisplays() {
        exec.run("timeout 25 " + script("brightness.sh", "list"), function(txt) {
            applyDisplays(txt === "" ? [] : txt.split("\n"))
        })
    }

    // ---------------- Popup handling ----------------
    readonly property bool classic: conf.classicPopup || dlgLoader.status === Loader.Error
    property bool dialogOpen: dlgLoader.item ? dlgLoader.item.visible : false
    readonly property bool popupOpen: classic ? expanded : dialogOpen
    onPopupOpenChanged: if (popupOpen) { copiedHex = ""; refresh(); refreshDisplays() }

    function togglePopup() {
        if (classic) expanded = !expanded
        else if (dlgLoader.item) dlgLoader.item.toggle()
    }
    function openPopup() {
        if (classic) expanded = true
        else if (dlgLoader.item) dlgLoader.item.visible = true
    }
    function closePopup() {
        if (classic) expanded = false
        else if (dlgLoader.item) dlgLoader.item.visible = false
    }

    Component { id: panelComp; Panel { ctl: root } }
    Loader {
        id: dlgLoader
        active: !root.conf.classicPopup
        source: "PopupDialog.qml"
        onLoaded: { item.ctl = root; item.panelComp = panelComp }
    }

    // ---------------- Actions ----------------
    function sh(cmd, delay) {
        exec.run(cmd)
        afterAction.interval = delay || 900
        afterAction.restart()
    }
    function closeAnd(cmd) { closePopup(); exec.run(cmd) }

    function setProfile(p) { profile = p; sh("powerprofilesctl set " + p) }
    function cycleProfile(dir, wrap) {
        var i = profiles.indexOf(profile)
        if (i < 0) i = 1
        var n = i + dir
        n = wrap ? (n + profiles.length) % profiles.length : Math.max(0, Math.min(profiles.length - 1, n))
        if (n !== i) setProfile(profiles[n])
    }
    function mpris(cmd) { if (player !== "") sh("playerctl -p '" + player + "' " + cmd, 500) }

    // ---- per-button behaviour (used by Panel.qml for every button, whatever its size) ----
    function entryOn(e) {
        switch (e.preset) {
        case "wifi": return wifiOn
        case "bluetooth": return btOn
        case "pen": return penOn
        case "profile": return profile !== "balanced"
        case "dnd": return dnd
        case "caffeine": return caffeine
        case "night": return night
        case "dark": return dark
        case "headset": return headphoneOn
        case "cloudflare": return warp
        case "airplane": return airplane
        case "mic": return micPresent && !micMuted
        case "custom": return customStates[e.uid] === true
        default: return false
        }
    }
    function entrySub(e) {
        switch (e.preset) {
        case "wifi": return wifiOn ? (wifiConn ? (wifiSsid !== "" ? wifiSsid : "Connected") : "On") : "Off"   // off / on / network name
        case "bluetooth": return btOn ? (btCount > 0 ? "Connected (" + btCount + ")" : "On - Not connected") : "Off"   // off / on / connected (devices)
        case "mic": return micMuted ? "Muted" : "On"
        case "profile": return profileName(profile)
        case "capture": case "record": return ""
        case "picker": return ""
        default: return entryOn(e) ? "On" : "Off"
        }
    }
    function entryIcon(e) {
        if (e.icon) return Presets.iconUrl(e.icon, iconBase)
        var c = Presets.find(e.preset)
        if (!c) return ""
        var file = c.icon
        if (e.preset === "profile")
            file = profile === "power-saver" ? "leaf.svg" : (profile === "performance" ? "rocket.svg" : "scale.svg")
        else if (c.iconOff && !entryOn(e)) file = c.iconOff
        return iconBase + file
    }
    function hasChevron(e) { var c = Presets.find(e.preset); return c !== null && c.chevron !== undefined }
    function entryChevron(e) { var c = Presets.find(e.preset); if (c && c.chevron) closeAnd("systemsettings " + c.chevron) }
    function entryWheel(e, dir) { if (e.preset === "profile") cycleProfile(dir, false) }
    function toggleCustom(e) {
        var st = {}
        for (var k in customStates) st[k] = customStates[k]
        var on = !(st[e.uid] === true)
        st[e.uid] = on
        Plasmoid.configuration.customStates = JSON.stringify(st)
        var cmd = on ? e.cmdOn : e.cmdOff
        if (cmd) sh(cmd, 900)
    }
    function entryClick(e) {
        switch (e.preset) {
        case "wifi": wifiOn = !wifiOn; sh("nmcli radio wifi " + (wifiOn ? "on" : "off"), 1500); break
        case "bluetooth":
            btOn = !btOn
            sh(btOn ? "rfkill unblock bluetooth; bluetoothctl power on" : "bluetoothctl power off", 1200)
            break
        case "pen": penOn = !penOn; if (e.cmdOn) sh("bash '" + e.cmdOn + "'", 2000); break
        case "profile": cycleProfile(1, true); break
        case "dnd": dnd = !dnd; sh(script("dnd.sh"), 1000); break
        case "caffeine": caffeine = !caffeine; sh(script("inhibit.sh", "caffeine --power --screenSaver"), 1000); break
        case "night": night = !night; sh(script("night.sh"), 1000); break
        case "dark": dark = !dark; sh("plasma-apply-colorscheme " + (dark ? conf.darkScheme : conf.lightScheme), 2000); break
        case "headset": headphoneOn = !headphoneOn; if (e.cmdOn) sh("bash '" + e.cmdOn + "'", 1200); break
        case "cloudflare": warp = !warp; sh(warp ? "warp-cli connect" : "warp-cli disconnect", 2500); break
        case "airplane": airplane = !airplane; sh(airplane ? "rfkill block all" : "rfkill unblock all", 1500); break
        case "capture": closeAnd("spectacle -r"); break
        case "record": closeAnd("spectacle --record region"); break
        case "picker": pickColor(); break
        case "mic": micMuted = !micMuted; sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", 500); break
        case "custom": toggleCustom(e); break
        }
    }

    // ---- colour picker history ----
    function addHistory(hex) {
        if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return
        hex = hex.toUpperCase()
        var a = pickerHistory.filter(function(x) { return x !== hex })
        a.unshift(hex)
        Plasmoid.configuration.pickerHistory = JSON.stringify(a.slice(0, 12))
    }
    property int pickSeq: 0
    property bool picking: false
    function pickColor() {
        if (picking) exec.run("pkill -f '[p]icker.sh pick'")      // a stale run (e.g. the picker was left open): stop it first
        closePopup()
        var my = ++pickSeq
        picking = true
        // the run number makes every command line unique, so a click is never swallowed by a run that is still going
        exec.run(script("picker.sh", "pick " + my), function(out) {
            if (my !== pickSeq) return                 // a newer run took over
            picking = false
            // take the last line that really is a colour (other tools may print extra lines)
            var lines = out.split("\n"), hex = ""
            for (var i = lines.length - 1; i >= 0 && hex === ""; i--)
                if (/^#[0-9a-fA-F]{6}$/.test(lines[i].trim())) hex = lines[i].trim()
            if (hex === "") return                     // cancelled
            addHistory(hex)
            openPopup()                                // bring the popup back: the new colour is in the history row
        })
    }
    function copyColor(hex) {
        exec.run(script("picker.sh", "copy '" + hex + "'"))
        copiedHex = hex
        copiedTimer.restart()
    }
    function clearHistory() { Plasmoid.configuration.pickerHistory = "[]" }
    Timer { id: copiedTimer; interval: 1800; onTriggered: root.copiedHex = "" }

    // ---------------- Optional: apply the blur slider to KWin's (system-wide) blur strength ----------------
    Timer { id: blurTimer; interval: 700; onTriggered: exec.run(root.script("blur.sh", String(root.conf.panelBlur))) }
    Connections {
        target: Plasmoid.configuration
        function onPanelBlurChanged() { if (root.conf.blurKwin) blurTimer.restart() }
        function onBlurKwinChanged() { if (root.conf.blurKwin) blurTimer.restart() }
    }

    // ---------------- Timers ----------------
    Timer { interval: 3000; running: root.popupOpen; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 6000; running: root.popupOpen; repeat: true; onTriggered: root.refreshDisplays() }
    Timer { id: afterAction; interval: 900; onTriggered: { root.refresh(); root.refreshColors() } }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refreshColors() }   // keeps light/dark in sync even while the popup is closed
    Timer {   // advance the song clock between refreshes
        interval: 1000
        running: root.popupOpen && root.mediaStatus === "Playing"
        repeat: true
        onTriggered: if (root.mediaPos < root.mediaLen) root.mediaPos += 1
    }
    Timer {   // send slider changes (throttled)
        interval: 120
        running: root.popupOpen
        repeat: true
        onTriggered: {
            if (root.pendingVol >= 0) {
                exec.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + root.pendingVol.toFixed(2))
                root.pendingVol = -1
            }
            var keys = Object.keys(root.pendingDisp)
            if (keys.length > 0) {
                keys.forEach(function(k) { exec.run(root.script("brightness.sh", "set '" + k + "' " + root.pendingDisp[k])) })
                root.pendingDisp = ({})
            }
        }
    }

    // ---------------- Representations ----------------
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        onClicked: root.togglePopup()
        Kirigami.Icon {
            anchors.fill: parent
            source: root.panelIconSource
            // a file icon keeps its own colours on the panel (turn "Keep SVG colors" off to tint it like text)
            isMask: root.panelIconIsFile && !root.conf.panelIconKeepColors
            color: Kirigami.Theme.textColor
            active: compact.containsMouse
        }
    }

    // only used by the classic (fallback) popup; the frameless popup lives in PopupDialog.qml
    fullRepresentation: Item {
        id: fr
        Layout.minimumWidth: ld.item ? ld.item.implicitWidth : 10
        Layout.preferredWidth: ld.item ? ld.item.implicitWidth : 10
        Layout.minimumHeight: ld.item ? ld.item.implicitHeight : 10
        Layout.preferredHeight: ld.item ? ld.item.implicitHeight : 10
        Loader {
            id: ld
            anchors.fill: parent
            active: root.classic
            sourceComponent: panelComp
        }
    }
}
