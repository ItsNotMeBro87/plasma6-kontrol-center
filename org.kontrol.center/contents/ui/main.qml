import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "Presets.js" as Presets
import "Strings.js" as Strings

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
    Component.onCompleted: { migrate(); refresh(); refreshDisplays(); refreshColors() }

    // settings written by an older version are adjusted once
    function migrate() {
        if (conf.cfgVersion < 770) {
            if (conf.mediaColorMode === "cover") Plasmoid.configuration.mediaColorMode = "coverDark"   // 0.7.7 has a dark and a light variant
        }
        if (conf.cfgVersion < 760) {
            // the "Transparent" checkbox is gone: the transparency slider alone decides now (0 = solid)
            if (!conf.panelTransparent) Plasmoid.configuration.panelTransparency = 0
            Plasmoid.configuration.cfgVersion = 760
        }
        if (conf.cfgVersion < 770) Plasmoid.configuration.cfgVersion = 770
    }

    // ---------------- Language ----------------
    function t(key, o) { return Strings.tr(conf.language, key, o) }
    readonly property var uiLocale: Qt.locale(Strings.localeOf(conf.language))
    function labelOf(e) {
        if (e.label) return e.label
        return e.preset === "custom" ? t("btn.custom") : t("btn." + e.preset)
    }

    // the popup never grows taller than the screen: the panel then shows scroll arrows instead
    readonly property int maxPanelHeight: Math.max(320, Screen.desktopAvailableHeight - 110)

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
    property bool stateTracking: false   // true once the saved Wi-Fi / Bluetooth / airplane state has been restored after login
    property bool restoreTried: false
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

        if (!restoreTried) {      // first status after login: put Wi-Fi / Bluetooth / airplane back as they were
            restoreTried = true
            exec.run(script("restore.sh", (conf.lastWifiOn ? 1 : 0) + " " + (conf.lastBtOn ? 1 : 0) + " " + (conf.lastAirplane ? 1 : 0)),
                     function() { trackTimer.start() })
        } else if (stateTracking) {
            if (!airplane) {
                if (wifiOn !== conf.lastWifiOn) Plasmoid.configuration.lastWifiOn = wifiOn
                if (btOn !== conf.lastBtOn) Plasmoid.configuration.lastBtOn = btOn
            }
            if (airplane !== conf.lastAirplane) Plasmoid.configuration.lastAirplane = airplane
        }

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
    onPopupOpenChanged: {
        if (popupOpen) { copiedHex = ""; refresh(); refreshDisplays() }
        else if (!picking) page = "main"      // reopen on the normal page (but not while the screen color picker is running)
    }

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
        case "wifi": return wifiOn ? (wifiConn ? (wifiSsid !== "" ? wifiSsid : t("connected")) : t("on")) : t("off")   // off / on / network name
        case "bluetooth": return btOn ? (btCount > 0 ? t("connected_n", { n: btCount }) : t("on_not_connected")) : t("off")   // off / on / connected (devices)
        case "mic": return micMuted ? t("muted") : t("on")
        case "profile": return t("profile." + profile)
        case "capture": case "record": return ""
        case "picker": return ""
        default: return entryOn(e) ? t("on") : t("off")
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
    // Wi-Fi, Bluetooth and Picker have an arrow (large) / a corner notch (small) that opens their own page inside the panel
    function hasChevron(e) { var c = Presets.find(e.preset); return c !== null && c.page !== undefined }
    function entryChevron(e, src) { var c = Presets.find(e.preset); if (c && c.page) openPage(c.page, src) }
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
        case "wifi": toggleWifi(); break
        case "bluetooth": toggleBluetooth(); break
        case "pen": penOn = !penOn; if (e.cmdOn) sh("bash '" + e.cmdOn + "'", 2000); break
        case "profile": cycleProfile(1, true); break
        case "dnd": dnd = !dnd; sh(script("dnd.sh"), 1000); break
        case "caffeine": caffeine = !caffeine; sh(script("inhibit.sh", "caffeine --power --screenSaver"), 1000); break
        case "night": night = !night; sh(script("night.sh"), 1000); break
        case "dark": dark = !dark; sh("plasma-apply-colorscheme " + (dark ? conf.darkScheme : conf.lightScheme), 2000); break
        case "headset": headphoneOn = !headphoneOn; if (e.cmdOn) sh("bash '" + e.cmdOn + "'", 1200); break
        case "cloudflare": warp = !warp; sh(warp ? "warp-cli connect" : "warp-cli disconnect", 2500); break
        case "airplane": toggleAirplane(); break
        case "capture": closeAnd("spectacle -r"); break
        case "record": closeAnd("spectacle --record region"); break
        case "picker": pickColor(); break
        case "mic": micMuted = !micMuted; sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", 500); break
        case "custom": toggleCustom(e); break
        }
    }

    function toggleWifi() {
        wifiOn = !wifiOn
        Plasmoid.configuration.lastWifiOn = wifiOn
        sh("nmcli radio wifi " + (wifiOn ? "on" : "off"), 1500)
    }
    property double btToggledAt: 0
    function toggleBluetooth() {
        btToggledAt = Date.now()
        btOn = !btOn
        Plasmoid.configuration.lastBtOn = btOn
        sh(script("bt.sh", "power " + (btOn ? "on" : "off")), 1200)
    }
    // Airplane mode remembers whether Wi-Fi and Bluetooth were on. Turning it off puts them back exactly like that
    // (a radio that was off stays off), instead of switching everything on.
    function toggleAirplane() {
        var turnOn = !airplane
        airplane = turnOn
        Plasmoid.configuration.lastAirplane = turnOn
        if (turnOn) {
            Plasmoid.configuration.airplaneSaved = JSON.stringify({ wifi: wifiOn, bt: btOn })
            wifiOn = false; btOn = false
            sh("rfkill block all", 1500)
        } else {
            var sv = parseJson(conf.airplaneSaved, {})
            var w = (sv && sv.wifi === false) ? 0 : 1
            var b = (sv && sv.bt === false) ? 0 : 1
            wifiOn = (w === 1); btOn = (b === 1)
            Plasmoid.configuration.lastWifiOn = wifiOn
            Plasmoid.configuration.lastBtOn = btOn
            sh(script("airplane.sh", "off " + w + " " + b), 7000)
        }
    }

    // ================= Expansion pages (Wi-Fi, Bluetooth, Picker, Sound) =================
    property string page: "main"          // main | wifi | bluetooth | picker | sound
    property string pageSrc: "large"      // "large" | "small" | "slider": the button that opened the page; its corner radius is reused
    function openPage(p, src) { pageSrc = src || "large"; page = p }
    function closePage() { page = "main" }
    // true while a refresh (Wi-Fi scan, Bluetooth scan) is really running: the refresh icon spins meanwhile
    property bool refreshing: false
    Timer { id: refreshGuard; interval: 20000; onTriggered: root.refreshing = false }
    function pageRefresh() {
        if (page === "wifi") wifiRescan()
        else if (page === "bluetooth") btRefresh()
        else if (page === "sound") refreshAudio()
    }
    onPageChanged: {
        wifiPrompt = ""; wifiMsg = ""; refreshing = false
        if (page !== "bluetooth") exec.run(script("bt.sh", "agent-stop"))
        if (page === "wifi") { refreshWifi(); wifiRescan() }
        else if (page === "bluetooth") { exec.run(script("bt.sh", "agent-start")); btRefresh() }
        else if (page === "sound") refreshAudio()
    }

    // names, passwords and addresses travel to the scripts hex-encoded (nothing in them can break a shell command)
    function toHex(s) {
        var enc = encodeURIComponent(String(s)), out = ""
        enc.replace(/%([0-9A-Fa-f]{2})|([^%])/g, function(m, h, ch) {
            var v = h ? h.toLowerCase() : ch.charCodeAt(0).toString(16)
            out += (v.length < 2 ? "0" : "") + v
            return ""
        })
        return out
    }
    function fromHex(h) { try { return decodeURIComponent(String(h).replace(/(..)/g, "%$1")) } catch (e) { return String(h) } }
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    property var pendingCmds: ({})
    function queueCmd(key, cmd) { var p = pendingCmds; p[key] = cmd; pendingCmds = p }

    // ---------------- Wi-Fi page ----------------
    property var wifiNets: []          // [{ ssid, signal(0-100, -1 = out of range), secure, band, enterprise, active, saved }]
    property string wifiIp: ""
    property string wifiPrompt: ""     // SSID that is waiting for a password
    property string wifiMsg: ""
    property string wifiBusySsid: ""
    property string wifiJson: ""
    readonly property var wifiCurrent: { var a = wifiNets.filter(function(n) { return n.active }); return a.length > 0 ? a[0] : null }
    function bandOf(f) { f = parseInt(f) || 0; return f === 0 ? "" : (f < 3000 ? "2.4 GHz" : (f < 5900 ? "5 GHz" : "6 GHz")) }
    function refreshWifi(done) { exec.run("timeout 20 " + script("wifi.sh", "list"), function(t) { applyWifi(t); if (done) done() }) }
    function wifiRescan() { refreshing = true; refreshGuard.restart(); exec.run("timeout 10 " + script("wifi.sh", "rescan")); rescanDone.restart() }
    Timer { id: rescanDone; interval: 2800; onTriggered: root.refreshWifi(function() { root.refreshing = false }) }
    function applyWifi(txt) {
        var nets = {}, saved = {}, ip = ""
        txt.split("\n").forEach(function(l) {
            var p = l.split("|")
            if (p[0] === "W" && p.length >= 7) {
                var ssid = fromHex(p[6]), sig = parseInt(p[2]) || 0, cur = nets[ssid]
                var act = p[1] === "1"
                if (!cur || sig > cur.signal || act)
                    nets[ssid] = { ssid: ssid, signal: sig, secure: p[3] === "1", band: bandOf(p[4]), enterprise: p[5] === "1",
                                   active: act || (cur ? cur.active : false) }
            } else if (p[0] === "S" && p.length >= 2) saved[fromHex(p[1])] = true
            else if (p[0] === "C") ip = p[1] || ""
        })
        var list = []
        for (var k in nets) { var n = nets[k]; n.saved = saved[k] === true; list.push(n) }
        for (var s in saved) if (!nets[s]) list.push({ ssid: s, signal: -1, secure: true, band: "", enterprise: false, active: false, saved: true })
        list.sort(function(a, b) { if (a.active !== b.active) return a.active ? -1 : 1; return b.signal - a.signal })
        var js = JSON.stringify({ l: list, ip: ip })
        if (js === wifiJson) return          // nothing changed: leave the list alone (keeps hover / typing intact)
        wifiJson = js; wifiNets = list; wifiIp = ip
    }
    function wifiConnect(ssid, pw) {
        wifiBusySsid = ssid; wifiMsg = ""
        exec.run("timeout 45 " + script("wifi.sh", "connect " + toHex(ssid) + (pw ? " " + toHex(pw) : "")), function(out) {
            wifiBusySsid = ""
            if (out.indexOf("ok") === 0) { wifiPrompt = ""; wifiMsg = "" } else wifiMsg = t("connect_failed")
            refreshWifi(); refresh()
        })
    }
    function wifiPick(n) {
        if (n.active || wifiBusySsid !== "") return
        if (n.saved || !n.secure) wifiConnect(n.ssid, "")
        else if (n.enterprise) { wifiPrompt = ""; wifiMsg = t("enterprise_hint") }
        else { wifiPrompt = n.ssid; wifiMsg = "" }
    }
    function wifiDisconnect() { exec.run(script("wifi.sh", "disconnect"), function() { refreshWifi(); refresh() }) }
    function wifiForget(ssid) { exec.run(script("wifi.sh", "forget " + toHex(ssid)), function() { refreshWifi() }) }

    // ---------------- Bluetooth page ----------------
    property bool btMissing: false
    property bool btDiscoverable: false
    property var btDevices: []         // [{ mac, name, connected, paired, trusted, icon, sig(-1 = unknown), sigKind, battery }]
    property var btRequest: null       // pairing request waiting for an answer: { kind, name, code }
    property var btBusy: ({})
    property string btJson: ""
    function refreshBt(done) { exec.run("timeout 14 " + script("bt.sh", "list"), function(t) { applyBt(t); if (done) done() }) }
    // manual refresh: scan for devices for a few seconds, then reload the list (the icon spins until then)
    function btRefresh() {
        refreshing = true; refreshGuard.restart()
        exec.run("timeout 14 " + script("bt.sh", "scan-wait"), function() { refreshBt(function() { root.refreshing = false }) })
    }
    function btScan() { exec.run(script("bt.sh", "scan")) }
    function applyBt(txt) {
        var devs = [], req = null, missing = false, powered = btOn, disc = false
        txt.split("\n").forEach(function(l) {
            var p = l.split("|")
            if (p[0] === "P") {
                if (p[1] === "missing") missing = true
                else { powered = (p[1] === "on"); disc = (p[2] === "on") }
            } else if (p[0] === "B" && p.length >= 9) {
                var rssi = p[6] === "" ? NaN : parseInt(p[6]), batt = p[7] === "" ? NaN : parseInt(p[7])
                var sig = -1, kind = ""
                if (!isNaN(rssi)) { sig = Math.max(0, Math.min(100, Math.round(2 * (rssi + 100)))); kind = "signal" }
                else if (!isNaN(batt)) { sig = Math.max(0, Math.min(100, batt)); kind = "battery" }
                devs.push({ mac: p[1], connected: p[2] === "1", paired: p[3] === "1", trusted: p[4] === "1",
                            icon: p[5], sig: sig, sigKind: kind, name: fromHex(p[8]) })
            } else if (p[0] === "Q" && p.length >= 4) {
                req = { kind: p[1], name: fromHex(p[2]), code: p[3] }
            }
        })
        devs.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return a.name.localeCompare(b.name)
        })
        var js = JSON.stringify({ d: devs, r: req, m: missing, o: powered, s: disc })
        btMissing = missing; btDiscoverable = disc
        if (Date.now() - btToggledAt > 3500) btOn = powered
        if (js === btJson) return
        btJson = js; btDevices = devs; btRequest = req
    }
    function setBusy(mac, on) { var b = {}; for (var k in btBusy) b[k] = btBusy[k]; if (on) b[mac] = true; else delete b[mac]; btBusy = b }
    function btConnect(mac) {
        setBusy(mac, true)
        exec.run("timeout 100 " + script("bt.sh", "connect " + mac), function() { setBusy(mac, false); refreshBt(); refresh() })
    }
    function btDisconnect(mac) {
        setBusy(mac, true)
        exec.run(script("bt.sh", "disconnect " + mac), function() { setBusy(mac, false); refreshBt(); refresh() })
    }
    function btRemove(mac) {
        setBusy(mac, true)
        exec.run(script("bt.sh", "remove " + mac), function() { setBusy(mac, false); refreshBt(); refresh() })
    }
    function btTrust(mac, on) {
        btDevices = btDevices.map(function(d) { if (d.mac === mac) { var c = {}; for (var k in d) c[k] = d[k]; c.trusted = on; return c } return d })
        exec.run(script("bt.sh", "trust " + mac + " " + (on ? "on" : "off")), function() { refreshBt() })
    }
    function btSetDiscoverable(on) {
        btDiscoverable = on
        exec.run(script("bt.sh", "discoverable " + (on ? "on" : "off")), function() { refreshBt() })
    }
    function btAnswer(yes, text) {
        exec.run(script("bt.sh", "answer " + (yes ? "yes" : "no") + " '" + String(text || "").replace(/[^A-Za-z0-9]/g, "") + "'"))
        btRequest = null; btJson = ""
        answerRefresh.restart()
    }
    Timer { id: answerRefresh; interval: 1200; onTriggered: root.refreshBt() }

    // ---------------- Sound page ----------------
    property string soundTab: "hardware"   // hardware | apps
    property var audioSinks: []            // [{ name, desc, vol(0-1), muted, isDefault, port, ports:[{ name, desc }] }]
    property var audioApps: []             // [{ idx, name, sub, icon, vol, muted }]
    property string audioJson: ""
    function refreshAudio() { exec.run("timeout 9 " + script("audio.sh", "dump"), applyAudio) }
    function volOf(v) {
        var m = 0
        for (var k in (v || {})) m = Math.max(m, parseInt(String(v[k].value_percent)) || 0)
        return Math.min(1, m / 100)
    }
    function applyAudio(txt) {
        if (isTouching()) return
        var def = "", sj = "[]", ij = "[]"
        txt.split("@@").forEach(function(chunk) {
            var nl = chunk.indexOf("\n")
            if (nl < 0) return
            var key = chunk.substring(0, nl).trim(), body = chunk.substring(nl + 1)
            if (key === "DEFAULT") def = body.trim()
            else if (key === "SINKS") sj = body
            else if (key === "INPUTS") ij = body
        })
        var sinks = [], apps = []
        try {
            JSON.parse(sj).forEach(function(s) {
                var ports = (s.ports || []).filter(function(p) { return p.availability !== "not available" })
                                           .map(function(p) { return { name: p.name, desc: p.description || p.name } })
                sinks.push({ name: s.name, desc: s.description || s.name, vol: volOf(s.volume), muted: s.mute === true,
                             isDefault: s.name === def, port: s.active_port || "", ports: ports })
            })
        } catch (e) {}
        try {
            JSON.parse(ij).forEach(function(a) {
                var pr = a.properties || {}
                var nm = pr["application.name"] || pr["application.process.binary"] || pr["media.name"] || "?"
                var ic = pr["application.icon_name"] || String(pr["application.process.binary"] || "").toLowerCase()
                apps.push({ idx: a.index, name: nm, sub: (pr["media.name"] && pr["media.name"] !== nm) ? pr["media.name"] : "",
                            icon: ic, vol: volOf(a.volume), muted: a.mute === true })
            })
        } catch (e2) {}
        var js = JSON.stringify({ s: sinks, a: apps })
        if (js === audioJson) return
        audioJson = js; audioSinks = sinks; audioApps = apps
    }
    Timer { id: audioSoon; interval: 1800; onTriggered: root.refreshAudio() }
    function setSinkVol(name, v) { touch(); audioSoon.restart(); queueCmd("sv:" + name, "pactl set-sink-volume " + q(name) + " " + Math.round(v * 100) + "%") }
    function setAppVol(idx, v) { touch(); audioSoon.restart(); queueCmd("av:" + idx, "pactl set-sink-input-volume " + idx + " " + Math.round(v * 100) + "%") }
    function toggleSinkMute(name) { exec.run("pactl set-sink-mute " + q(name) + " toggle", function() { refreshAudio(); refresh() }) }
    function toggleAppMute(idx) { exec.run("pactl set-sink-input-mute " + idx + " toggle", function() { refreshAudio() }) }
    function setDefaultSink(name) { exec.run("pactl set-default-sink " + q(name), function() { refreshAudio(); refresh() }) }
    function setSinkPort(name, port) { exec.run("pactl set-sink-port " + q(name) + " " + q(port), function() { refreshAudio() }) }

    // ---- colour picker history ----
    function addHistory(hex) {
        if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return
        hex = hex.toUpperCase()
        var a = pickerHistory.filter(function(x) { return x !== hex })
        a.unshift(hex)
        Plasmoid.configuration.pickerHistory = JSON.stringify(a.slice(0, 20))     // newest first, at most 20; a repeated color moves to the front
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
    function removeHistory(hex) { Plasmoid.configuration.pickerHistory = JSON.stringify(pickerHistory.filter(function(x) { return x !== hex })) }
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
    Timer { interval: 4000; running: root.popupOpen && root.page === "wifi"; repeat: true; onTriggered: root.refreshWifi() }
    Timer { interval: 2500; running: root.popupOpen && root.page === "bluetooth"; repeat: true; onTriggered: root.refreshBt() }
    Timer { interval: 13000; running: root.popupOpen && root.page === "bluetooth"; repeat: true; onTriggered: root.btScan() }
    Timer { interval: 2500; running: root.popupOpen && root.page === "sound"; repeat: true; onTriggered: root.refreshAudio() }
    Timer { id: trackTimer; interval: 8000; onTriggered: root.stateTracking = true }
    Timer { interval: 120000; running: !root.popupOpen && root.stateTracking; repeat: true; onTriggered: root.refresh() }   // keeps the remembered Wi-Fi / Bluetooth state current
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
            var ck = Object.keys(root.pendingCmds)
            if (ck.length > 0) {
                ck.forEach(function(k) { exec.run(root.pendingCmds[k]) })
                root.pendingCmds = ({})
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
