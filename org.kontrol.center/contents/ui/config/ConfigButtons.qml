import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.plasma5support as P5Support
import "../Presets.js" as Presets

KCMUtils.SimpleKCM {
    id: page

    property string cfg_buttonsJson
    property string cfg_buttonsJsonDefault
    property string cfg_sectionOrder
    property string cfg_sectionOrderDefault
    property int cfg_wheelVolume
    property int cfg_wheelVolumeDefault
    property int cfg_wheelBrightness
    property int cfg_wheelBrightnessDefault
    property bool cfg_showDate
    property bool cfg_showDateDefault
    property string cfg_dateFormat
    property string cfg_dateFormatDefault
    property bool cfg_showUptime
    property bool cfg_showUptimeDefault
    property string cfg_mprisMatch
    property string cfg_mprisMatchDefault
    property string cfg_darkScheme
    property string cfg_darkSchemeDefault
    property string cfg_lightScheme
    property string cfg_lightSchemeDefault

    readonly property string iconBase: Qt.resolvedUrl("../../icons/").toString()

    // Section keys: "brightness", "volume", "large", "small", "media", each as many times as you like:
    // "brightness", "brightness#2", "volume#2", "media#3", ...  Every button has a `group` = the key of the section it lives in.
    // (older versions had one combined "sliders" part: it is turned into a brightness + a volume part)
    ListModel { id: orderModel }          // skey, kind, label
    property var groupModels: ({})        // section key -> ListModel of buttons
    property var orphans: []              // buttons of removed sections: kept, so re-adding the section brings them back
    property var addChoices: []

    property string selGroup: ""          // section key of the selected button
    property int selIndex: -1
    property var selEntry: ({})
    property bool selfChange: false

    // ------------------------------------------------------------------ helpers
    function str(v) { return (v === undefined || v === null) ? "" : String(v) }
    function kindOf(key) { return String(key).split("#")[0] }
    function labelFor(key) {
        var k = kindOf(key)
        var base = k === "brightness" ? "Brightness slider" : (k === "volume" ? "Volume slider"
                   : (k === "large" ? "Large buttons" : (k === "small" ? "Small buttons" : "Media banner")))
        var n = String(key).indexOf("#") >= 0 ? " " + String(key).split("#")[1] : ""
        return base + n
    }
    function norm(b) {
        var size = b.size === "large" ? "large" : "small"
        return { preset: str(b.preset) || "custom", size: size,
                 label: str(b.label), icon: str(b.icon), cmdOn: str(b.cmdOn), cmdOff: str(b.cmdOff),
                 arg: str(b.arg), uid: str(b.uid), group: str(b.group) || size }
    }
    function rowToObj(m) {
        return { preset: str(m.preset), size: str(m.size), label: str(m.label), icon: str(m.icon),
                 cmdOn: str(m.cmdOn), cmdOff: str(m.cmdOff), arg: str(m.arg), uid: str(m.uid), group: str(m.group) }
    }
    function makeModel() { return Qt.createQmlObject('import QtQuick; ListModel {}', page) }
    function orderKeys() {
        var k = []
        for (var i = 0; i < orderModel.count; i++) k.push(orderModel.get(i).skey)
        return k
    }
    function selKind() { return kindOf(selGroup) }
    function clearSel() { selGroup = ""; selIndex = -1; selEntry = ({}) }

    readonly property var kinds: ["brightness", "volume", "large", "small", "media"]
    function kindIcon(k) {
        return k === "brightness" ? "sun.svg" : (k === "volume" ? "volume.svg" : (k === "large" ? "scale.svg"
               : (k === "small" ? "bulb.svg" : "music.svg")))
    }
    // every kind can be added again and again (to try a look; remove it again with the bin)
    function refreshChoices() {
        addChoices = [
            { id: "brightness", label: "Brightness slider" },
            { id: "volume",     label: "Volume slider" },
            { id: "large",      label: "Group of large buttons" },
            { id: "small",      label: "Group of small buttons" },
            { id: "media",      label: "Media banner" }
        ]
    }

    function loadAll() {
        orderModel.clear()
        groupModels = ({})
        orphans = []
        clearSel()

        var arr = []
        try { arr = JSON.parse(cfg_buttonsJson) } catch (e) { arr = [] }
        if (!Array.isArray(arr) || arr.length === 0) {
            try { arr = JSON.parse(Presets.defaultButtonsJson) } catch (e2) { arr = [] }
        }

        var keys = []
        var legacy = false
        function addKey(k) { if (keys.indexOf(k) < 0) keys.push(k) }
        str(cfg_sectionOrder).split(",").forEach(function(k) {
            k = k.trim()
            if (k === "") return
            if (k === "sliders") { legacy = true; addKey("brightness"); addKey("volume"); return }
            if (kinds.indexOf(kindOf(k)) < 0) return
            addKey(k)
        })

        var models = {}
        keys.forEach(function(k) { if (kindOf(k) === "large" || kindOf(k) === "small") models[k] = makeModel() })
        var orph = []
        arr.forEach(function(b) {
            var m = norm(b)
            if (models[m.group]) models[m.group].append(m)
            else orph.push(m)
        })
        groupModels = models
        orphans = orph
        keys.forEach(function(k) { orderModel.append({ skey: k, kind: kindOf(k), label: labelFor(k) }) })
        refreshChoices()
        if (legacy) saveOrder()
    }

    function saveButtons() {
        var out = []
        orderKeys().forEach(function(k) {
            var m = groupModels[k]
            if (!m) return
            for (var i = 0; i < m.count; i++) out.push(rowToObj(m.get(i)))
        })
        orphans.forEach(function(o) { out.push(o) })
        selfChange = true
        cfg_buttonsJson = JSON.stringify(out)
        selfChange = false
    }
    function saveOrder() {
        selfChange = true
        cfg_sectionOrder = orderKeys().join(",")
        selfChange = false
    }
    onCfg_buttonsJsonChanged: if (!selfChange) loadAll()
    onCfg_sectionOrderChanged: if (!selfChange) loadAll()
    Component.onCompleted: { loadAll(); refreshProfiles() }

    // ------------------------------------------------------------------ sections
    function moveSection(i, dir) {
        var to = i + dir
        if (to < 0 || to >= orderModel.count) return
        orderModel.move(i, to, 1)
        saveOrder()
    }
    function removeSection(i) {
        var key = orderModel.get(i).skey
        var m = groupModels[key]
        if (m) {
            var o = orphans.slice()
            for (var j = 0; j < m.count; j++) o.push(rowToObj(m.get(j)))
            orphans = o
        }
        if (selGroup === key) clearSel()
        orderModel.remove(i)
        saveButtons()
        saveOrder()
    }
    // returns the key of the new section
    function addSection(kind) {
        var present = orderKeys(), n = 1
        while (present.indexOf(n === 1 ? kind : kind + "#" + n) >= 0) n++
        var key = n === 1 ? kind : kind + "#" + n
        if (kind === "large" || kind === "small") {
            var m = makeModel()
            var rest = []
            orphans.forEach(function(o) { if (o.group === key) m.append(o); else rest.push(o) })
            orphans = rest
            var g = groupModels
            g[key] = m
            groupModels = g
        }
        orderModel.append({ skey: key, kind: kindOf(key), label: labelFor(key) })
        saveButtons()
        saveOrder()
        return key
    }

    // ------------------------------------------------------------------ buttons
    function moveIn(key, from, to) {
        var m = groupModels[key]
        m.move(from, to, 1)
        if (selGroup === key) {
            if (selIndex === from) selIndex = to
            else if (from < selIndex && selIndex <= to) selIndex -= 1
            else if (to <= selIndex && selIndex < from) selIndex += 1
        }
        saveButtons()
    }
    function syncEditor() {
        presetBox.currentIndex = Presets.indexOfPreset(selEntry.preset)
        labelField.text = str(selEntry.label)
        iconField.value = str(selEntry.icon)
        cmdOnField.text = str(selEntry.cmdOn)
        cmdOffField.text = str(selEntry.cmdOff)
        argField.text = str(selEntry.arg)
    }
    function select(key, idx) {
        var m = groupModels[key]
        if (!m || idx < 0 || idx >= m.count) return
        selGroup = key
        selIndex = idx
        selEntry = rowToObj(m.get(idx))
        syncEditor()
    }
    function setField(name, v) {
        var m = groupModels[selGroup]
        if (!m || selIndex < 0 || selIndex >= m.count) return
        m.setProperty(selIndex, name, v)
        if (name === "preset" && v === "custom" && str(m.get(selIndex).uid) === "")
            m.setProperty(selIndex, "uid", "c" + Date.now())
        selEntry = rowToObj(m.get(selIndex))
        syncEditor()
        saveButtons()
    }
    function addButton(key, presetId) {
        var m = groupModels[key]
        if (!m) return
        var e = norm(Presets.defaultEntry(presetId, kindOf(key)))
        e.group = key
        m.append(e)
        saveButtons()
        select(key, m.count - 1)
    }
    function removeSel() {
        var m = groupModels[selGroup]
        if (!m || selIndex < 0 || selIndex >= m.count) return
        m.remove(selIndex)
        clearSel()
        saveButtons()
    }
    function convertSel() {
        if (selGroup === "" || selIndex < 0) return
        var from = groupModels[selGroup]
        var toKind = selKind() === "large" ? "small" : "large"
        var target = ""
        var keys = orderKeys()
        for (var i = 0; i < keys.length; i++) if (kindOf(keys[i]) === toKind) { target = keys[i]; break }
        if (target === "") target = addSection(toKind)
        var e = rowToObj(from.get(selIndex))
        e.size = toKind
        e.group = target
        from.remove(selIndex)
        groupModels[target].append(e)
        saveButtons()
        select(target, groupModels[target].count - 1)
    }
    function moveSel(dir) {
        var m = groupModels[selGroup]
        if (!m) return
        var to = selIndex + dir
        if (to < 0 || to >= m.count) return
        moveIn(selGroup, selIndex, to)
    }
    function resetLayout() {
        cfg_buttonsJson = Presets.defaultButtonsJson
        cfg_sectionOrder = Presets.defaultOrder
        loadAll()
    }
    function entryLabel(m) { return Presets.labelOf(m) }
    function entryIcon(m) {
        return Presets.iconUrl(m.icon !== "" ? m.icon : Presets.defaultIconFile(m.preset), page.iconBase)
    }

    // ------------------------------------------------------------------ profiles (saved as files on this PC)
    readonly property string scriptDir: decodeURIComponent(Qt.resolvedUrl("../../scripts/").toString().replace("file://", ""))
    property var profileList: []           // [{ name, data }]
    property string profileName: ""
    property string profileMsg: ""

    P5Support.DataSource {
        id: pexec
        engine: "executable"
        connectedSources: []
        property var cbs: ({})
        onNewData: function(source, data) {
            pexec.disconnectSource(source)
            var cb = cbs[source]
            delete cbs[source]
            if (cb) cb((data["stdout"] || "").trim())
        }
        function run(cmd, cb) { if (cb) cbs[cmd] = cb; connectSource(cmd) }
    }
    function pscript(args) { return "bash '" + scriptDir + "profiles.sh' " + args }
    function cleanName(n) { return String(n).replace(/[^A-Za-z0-9 ._-]/g, "_").replace(/^[. ]+/, "").replace(/ +$/, "") }
    // plain ASCII JSON (\uXXXX escapes), so base64 / the shell can never mangle it
    function asciiJson(o) {
        return JSON.stringify(o).replace(/[\u0080-\uffff]/g, function(c) { return "\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4) })
    }
    function refreshProfiles() {
        pexec.run(pscript("list"), function(out) {
            var a = []
            out.split("\n").forEach(function(l) {
                var i = l.indexOf("|")
                if (i <= 0) return
                var d = null
                try { d = JSON.parse(Qt.atob(l.substring(i + 1))) } catch (e) { d = null }
                a.push({ name: l.substring(0, i), valid: d !== null && d.buttonsJson !== undefined, data: d })
            })
            profileList = a
        })
    }
    function saveProfile() {
        var n = cleanName(profileName)
        if (n === "") { profileMsg = "Type a name for the profile first."; return }
        var data = { kontrolCenter: "layout-profile", version: 1, savedWith: "0.7.5 Beta",
                     sectionOrder: cfg_sectionOrder, buttonsJson: cfg_buttonsJson }
        pexec.run(pscript("save '" + n + "' '" + Qt.btoa(asciiJson(data)) + "'"), function() {
            profileMsg = "Saved \"" + n + "\"."
            profileName = ""
            refreshProfiles()
        })
    }
    function loadProfile(entry) {
        if (!entry.valid) { profileMsg = "That profile file could not be read."; return }
        cfg_buttonsJson = entry.data.buttonsJson
        cfg_sectionOrder = entry.data.sectionOrder || Presets.defaultOrder
        loadAll()
        profileMsg = "Loaded \"" + entry.name + "\". Press Apply to keep it."
    }
    function deleteProfile(n) {
        pexec.run(pscript("delete '" + n + "'"), function() { profileMsg = "Deleted \"" + n + "\"."; refreshProfiles() })
    }
    function dateIndex() {
        for (var i = 0; i < Presets.dateFormats.length; i++) if (Presets.dateFormats[i].id === cfg_dateFormat) return i
        return 0
    }

    // ------------------------------------------------------------------ UI
    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading { level: 3; text: "Panel layout" }
        QQC2.Label {
            text: "These are the parts of the widget, top to bottom. Drag a part in the list below (or use the arrows) to choose what sits on top and what sits at the bottom. Click a button to edit it; drag a button onto another one to reorder it inside its group."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
        }

        Kirigami.Heading { level: 4; text: "Order of the parts (drag to reorder)" }
        DragGrid {
            model: orderModel
            columns: 1
            cellW: 320
            cellH: 36
            labelFn: function(m) { return m ? m.label : "" }
            iconFn: function(m) { return m ? page.iconBase + page.kindIcon(m.kind) : "" }
            onMove: function(f, t) { orderModel.move(f, t, 1); page.saveOrder() }
        }

        Repeater {
            model: orderModel
            delegate: ColumnLayout {
                id: sec
                required property int index
                required property string skey
                required property string kind
                required property string label
                readonly property bool isGroup: kind === "large" || kind === "small"
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Separator { Layout.fillWidth: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Heading { level: 4; text: sec.label; Layout.fillWidth: true }
                    QQC2.ToolButton {
                        icon.name: "go-up"
                        enabled: sec.index > 0
                        QQC2.ToolTip.text: "Move up"
                        QQC2.ToolTip.visible: hovered
                        onClicked: page.moveSection(sec.index, -1)
                    }
                    QQC2.ToolButton {
                        icon.name: "go-down"
                        enabled: sec.index < orderModel.count - 1
                        QQC2.ToolTip.text: "Move down"
                        QQC2.ToolTip.visible: hovered
                        onClicked: page.moveSection(sec.index, 1)
                    }
                    QQC2.ToolButton {
                        icon.name: "edit-delete"
                        QQC2.ToolTip.text: "Remove this part from the panel"
                        QQC2.ToolTip.visible: hovered
                        onClicked: page.removeSection(sec.index)
                    }
                }

                QQC2.Label {
                    visible: !sec.isGroup
                    text: sec.kind === "brightness" ? "Brightness slider (one bar for every screen it can control)."
                        : (sec.kind === "volume" ? "Volume slider with a shortcut to the sound settings."
                                                 : "Now-playing banner.")
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 32
                }

                DragGrid {
                    visible: sec.isGroup
                    model: sec.isGroup ? page.groupModels[sec.skey] : null
                    columns: sec.kind === "large" ? 2 : 6
                    cellW: sec.kind === "large" ? 200 : 78
                    cellH: 54
                    selected: page.selGroup === sec.skey ? page.selIndex : -1
                    labelFn: page.entryLabel
                    iconFn: page.entryIcon
                    onPick: function(i) { page.select(sec.skey, i) }
                    onMove: function(f, t) { page.moveIn(sec.skey, f, t) }
                }
                RowLayout {
                    visible: sec.isGroup
                    spacing: Kirigami.Units.smallSpacing
                    QQC2.ComboBox {
                        id: addBox
                        model: Presets.catalog.map(function(c) { return c.label })
                    }
                    QQC2.Button {
                        text: "Add button"
                        icon.name: "list-add"
                        onClicked: page.addButton(sec.skey, Presets.catalog[addBox.currentIndex].id)
                    }
                    QQC2.Button {
                        text: "Remove selected"
                        icon.name: "edit-delete"
                        enabled: page.selGroup === sec.skey && page.selIndex >= 0
                        onClicked: page.removeSel()
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.Label { text: "Add to the panel:" }
            QQC2.ComboBox {
                id: addSecBox
                model: page.addChoices.map(function(c) { return c.label })
            }
            QQC2.Button {
                text: "Add"
                icon.name: "list-add"
                enabled: page.addChoices.length > 0
                onClicked: if (addSecBox.currentIndex >= 0) page.addSection(page.addChoices[addSecBox.currentIndex].id)
            }
            QQC2.Button {
                text: "Reset layout"
                icon.name: "edit-undo"
                onClicked: page.resetLayout()
            }
        }
        QQC2.Label {
            text: "Every part can be added as many times as you like, so you can try a look and bin it again if it does not suit you. You can also use the same button several times - that is how you get a large and a small version of it."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
        }

        // ---------------- editor for the selected button ----------------
        Kirigami.FormLayout {
            id: editor
            visible: page.selGroup !== "" && page.selIndex >= 0
            Layout.fillWidth: true

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Edit selected button" }
            QQC2.ComboBox {
                id: presetBox
                Kirigami.FormData.label: "Type:"
                model: Presets.catalog.map(function(c) { return c.label })
                onActivated: function(i) { page.setField("preset", Presets.catalog[i].id) }
            }
            QQC2.TextField {
                id: labelField
                Kirigami.FormData.label: "Name:"
                placeholderText: "(default name)"
                Layout.preferredWidth: 260
                onEditingFinished: page.setField("label", text)
            }
            IconField {
                id: iconField
                Kirigami.FormData.label: "Icon:"
                placeholder: "(default icon)"
                onPicked: function(v) { page.setField("icon", v) }
            }
            QQC2.TextField {
                id: cmdOnField
                visible: page.selEntry.preset === "custom" || page.selEntry.preset === "pen" || page.selEntry.preset === "headset"
                Kirigami.FormData.label: page.selEntry.preset === "custom" ? "Command when turned ON:" : "Toggle script:"
                placeholderText: page.selEntry.preset === "custom" ? "e.g. /home/you/my-script.sh on" : "/path/to/script.sh"
                Layout.preferredWidth: 360
                onEditingFinished: page.setField("cmdOn", text)
            }
            QQC2.TextField {
                id: cmdOffField
                visible: page.selEntry.preset === "custom"
                Kirigami.FormData.label: "Command when turned OFF:"
                placeholderText: "e.g. /home/you/my-script.sh off"
                Layout.preferredWidth: 360
                onEditingFinished: page.setField("cmdOff", text)
            }
            QQC2.TextField {
                id: argField
                visible: page.selEntry.preset === "pen"
                Kirigami.FormData.label: "Screen name:"
                placeholderText: "HDMI-A-1  (used to detect if the display is on)"
                Layout.preferredWidth: 360
                onEditingFinished: page.setField("arg", text)
            }
            RowLayout {
                Kirigami.FormData.label: "Position:"
                QQC2.Button {
                    text: "Move earlier"
                    icon.name: "go-previous"
                    enabled: page.selIndex > 0
                    onClicked: page.moveSel(-1)
                }
                QQC2.Button {
                    text: "Move later"
                    icon.name: "go-next"
                    enabled: page.selGroup !== "" && groupModels[page.selGroup] !== undefined && page.selIndex < groupModels[page.selGroup].count - 1
                    onClicked: page.moveSel(1)
                }
            }
            RowLayout {
                Kirigami.FormData.label: ""
                QQC2.Button {
                    text: page.selKind() === "large" ? "Move to a small buttons group" : "Move to a large buttons group"
                    icon.name: "go-jump"
                    onClicked: page.convertSel()
                }
                QQC2.Button {
                    text: "Remove"
                    icon.name: "edit-delete"
                    onClicked: page.removeSel()
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ---------------- profiles ----------------
        Kirigami.Heading { level: 3; text: "Profiles" }
        QQC2.Label {
            text: "Save the current layout and buttons under a name, and load it again later. Profiles are plain files in ~/.local/share/kontrol-center/profiles on this PC, and you can save as many as you like. Loading a profile replaces the current layout and buttons (press Apply to keep it)."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
        }
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.TextField {
                Layout.preferredWidth: 220
                placeholderText: "Profile name"
                text: page.profileName
                onTextEdited: page.profileName = text
                onAccepted: page.saveProfile()
            }
            QQC2.Button {
                text: "Save current layout"
                icon.name: "document-save"
                onClicked: page.saveProfile()
            }
        }
        QQC2.Label { visible: page.profileMsg !== ""; text: page.profileMsg; opacity: 0.8 }
        QQC2.Label { visible: page.profileList.length === 0; text: "No saved profiles yet."; opacity: 0.6 }
        Repeater {
            model: page.profileList
            delegate: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label { text: modelData.name; Layout.preferredWidth: 220; elide: Text.ElideRight }
                QQC2.Button { text: "Load"; icon.name: "document-open"; enabled: modelData.valid; onClicked: page.loadProfile(modelData) }
                QQC2.Button { icon.name: "edit-delete"; QQC2.ToolTip.visible: hovered; QQC2.ToolTip.text: "Delete this profile"; onClicked: page.deleteProfile(modelData.name) }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ---------------- header + behaviour ----------------
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Header (top left)" }
            QQC2.CheckBox {
                Kirigami.FormData.label: "Day and date:"
                text: "Show"
                checked: page.cfg_showDate
                onToggled: page.cfg_showDate = checked
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Date format:"
                enabled: page.cfg_showDate
                Layout.preferredWidth: 360
                model: Presets.dateFormats.map(function(f) { return f.label })
                currentIndex: page.dateIndex()
                onActivated: function(i) { page.cfg_dateFormat = Presets.dateFormats[i].id }
            }
            QQC2.CheckBox {
                Kirigami.FormData.label: "Uptime:"
                text: "Show under the date"
                checked: page.cfg_showUptime
                onToggled: page.cfg_showUptime = checked
            }
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Behavior" }
            QQC2.SpinBox {
                Kirigami.FormData.label: "Volume wheel step (%):"
                from: 1; to: 20; editable: true
                value: page.cfg_wheelVolume
                onValueModified: page.cfg_wheelVolume = value
            }
            QQC2.SpinBox {
                Kirigami.FormData.label: "Brightness wheel step (%):"
                from: 1; to: 25; editable: true
                value: page.cfg_wheelBrightness
                onValueModified: page.cfg_wheelBrightness = value
            }
            QQC2.TextField {
                Kirigami.FormData.label: "Media player filter:"
                placeholderText: "empty = any player, e.g.  ytm, spotify"
                Layout.preferredWidth: 320
                text: page.cfg_mprisMatch
                onEditingFinished: page.cfg_mprisMatch = text
            }
            QQC2.Label {
                Kirigami.FormData.label: ""
                text: "Leave empty to use any player. To limit the banner to certain players, type part of their names. To allow several players, separate them with a comma, for example:  ytm, spotify  (ytm-player and Spotify). The player that is playing right now is shown; if several are, the first one in the list wins. Names are not case sensitive. Run  playerctl -l  in a terminal to see the exact player names."
                wrapMode: Text.WordWrap
                opacity: 0.7
                Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            }
            QQC2.TextField {
                Kirigami.FormData.label: "Dark color scheme:"
                Layout.preferredWidth: 200
                text: page.cfg_darkScheme
                onEditingFinished: page.cfg_darkScheme = text
            }
            QQC2.TextField {
                Kirigami.FormData.label: "Light color scheme:"
                Layout.preferredWidth: 200
                text: page.cfg_lightScheme
                onEditingFinished: page.cfg_lightScheme = text
            }
        }
    }
}
