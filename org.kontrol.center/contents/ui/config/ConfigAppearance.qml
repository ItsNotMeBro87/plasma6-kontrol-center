import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page

    property string cfg_panelColor
    property string cfg_panelColorDefault
    property int cfg_panelRadius
    property int cfg_panelRadiusDefault
    property int cfg_panelWidth
    property int cfg_panelWidthDefault
    property int cfg_panelScale
    property int cfg_panelScaleDefault
    property int cfg_panelShadowBlur
    property int cfg_panelShadowBlurDefault
    property int cfg_btnShadowBlur
    property int cfg_btnShadowBlurDefault
    property int cfg_mediaShadowBlur
    property int cfg_mediaShadowBlurDefault
    property int cfg_panelTransparency
    property int cfg_panelTransparencyDefault
    property int cfg_panelBlur
    property int cfg_panelBlurDefault
    property bool cfg_blurKwin
    property bool cfg_blurKwinDefault
    property bool cfg_textLegibility
    property bool cfg_textLegibilityDefault
    property bool cfg_classicPopup
    property bool cfg_classicPopupDefault
    property bool cfg_followSystem
    property bool cfg_followSystemDefault
    property bool cfg_panelBorder
    property bool cfg_panelBorderDefault
    property string cfg_panelBorderColor
    property string cfg_panelBorderColorDefault
    property int cfg_panelBorderWidth
    property int cfg_panelBorderWidthDefault
    property bool cfg_panelShadow
    property bool cfg_panelShadowDefault
    property string cfg_panelShadowColor
    property string cfg_panelShadowColorDefault
    property int cfg_sliderRadius
    property int cfg_sliderRadiusDefault
    property int cfg_largeRadius
    property int cfg_largeRadiusDefault
    property int cfg_smallRadius
    property int cfg_smallRadiusDefault
    property int cfg_mediaRadius
    property int cfg_mediaRadiusDefault
    property string cfg_offColor
    property string cfg_offColorDefault
    property string cfg_onColor
    property string cfg_onColorDefault
    property bool cfg_useAccent
    property bool cfg_useAccentDefault
    property bool cfg_useAccentOff
    property bool cfg_useAccentOffDefault
    property bool cfg_offColorCustom
    property bool cfg_offColorCustomDefault
    property bool cfg_btnBorder
    property bool cfg_btnBorderDefault
    property string cfg_btnBorderColor
    property string cfg_btnBorderColorDefault
    property int cfg_btnBorderWidth
    property int cfg_btnBorderWidthDefault
    property bool cfg_btnShadow
    property bool cfg_btnShadowDefault
    property string cfg_btnShadowColor
    property string cfg_btnShadowColorDefault
    property string cfg_recentColors
    property string cfg_recentColorsDefault
    property string cfg_mediaColorMode
    property string cfg_mediaColorModeDefault
    property string cfg_mediaColor
    property string cfg_mediaColorDefault
    property bool cfg_mediaShowIdle
    property bool cfg_mediaShowIdleDefault
    property bool cfg_mediaBorder
    property bool cfg_mediaBorderDefault
    property string cfg_mediaBorderColor
    property string cfg_mediaBorderColorDefault
    property int cfg_mediaBorderWidth
    property int cfg_mediaBorderWidthDefault
    property bool cfg_mediaShadow
    property bool cfg_mediaShadowDefault
    property string cfg_mediaShadowColor
    property string cfg_mediaShadowColorDefault

    // ---- recent colours (shared by every colour field below; newest first, at most 12)
    readonly property var recentList: {
        try { var a = JSON.parse(cfg_recentColors); return Array.isArray(a) ? a : [] } catch (e) { return [] }
    }
    function setColor(key, hex) {
        hex = String(hex).toLowerCase()
        page["cfg_" + key] = hex
        if (key === "offColor") cfg_offColorCustom = true
        var a = recentList.filter(function(x) { return String(x).toLowerCase() !== hex })
        a.unshift(hex)
        cfg_recentColors = JSON.stringify(a.slice(0, 12))
    }

    Kirigami.FormLayout {

        // ---------------- Panel ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Panel" }
        SliderField {
            Kirigami.FormData.label: "Corner radius:"
            value: page.cfg_panelRadius
            to: 40
            suffix: "px"
            onEdited: function(v) { page.cfg_panelRadius = v }
        }
        SliderField {
            Kirigami.FormData.label: "Width:"
            from: 320
            to: 640
            value: page.cfg_panelWidth
            suffix: "px"
            onEdited: function(v) { page.cfg_panelWidth = v }
        }
        SliderField {
            Kirigami.FormData.label: "Scale:"
            from: 70
            to: 160
            value: page.cfg_panelScale
            suffix: "%"
            onEdited: function(v) { page.cfg_panelScale = v }
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Width only changes how wide the panel is. Scale enlarges or shrinks the whole Kontrol Center in both directions: the panel and everything in it (buttons, sliders, banner, texts)."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "The height always follows what is shown: it is as short or as long as the buttons, sliders and banners you added need (with scroll arrows if the screen is too small)."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Colors:"
            text: "Follow system light / dark mode"
            checked: page.cfg_followSystem
            onToggled: page.cfg_followSystem = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Changes the panel color, and the Off buttons too until you pick your own."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        ColorField {
            Kirigami.FormData.label: "Panel color:"
            enabled: !page.cfg_followSystem
            opacity: enabled ? 1.0 : 0.4
            recent: page.recentList
            value: page.cfg_panelColor
            onPicked: function(h) { page.setColor("panelColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Transparency:"
            value: page.cfg_panelTransparency
            to: 100
            suffix: "%"
            onEdited: function(v) { page.cfg_panelTransparency = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: ""
            text: "Keep text and icons readable on a see-through panel"
            checked: page.cfg_textLegibility
            onToggled: page.cfg_textLegibility = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Adds a thin outline around the date, uptime, button names and header icons while the panel is see-through, so they do not disappear into the wallpaper."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        SliderField {
            Kirigami.FormData.label: "Blur:"
            value: page.cfg_panelBlur
            to: 100
            suffix: "%"
            onEdited: function(v) { page.cfg_panelBlur = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: ""
            enabled: page.cfg_panelBlur > 0
            text: "Also use this value as KWin's blur strength"
            checked: page.cfg_blurKwin
            onToggled: page.cfg_blurKwin = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Blur is drawn by KWin behind Plasma's own frame, so it needs the Blur desktop effect and a see-through panel (with Transparency at 0 the panel is made 28% see-through automatically). KWin has no per-widget blur strength: the strength is one system-wide setting (System Settings > Desktop Effects > Blur). Ticking the box above makes this slider change that system-wide strength, which affects ALL blurred windows."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Border:"
            text: "Show a border"
            checked: page.cfg_panelBorder
            onToggled: page.cfg_panelBorder = checked
        }
        ColorField {
            visible: page.cfg_panelBorder
            recent: page.recentList
            value: page.cfg_panelBorderColor
            onPicked: function(h) { page.setColor("panelBorderColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Border width:"
            visible: page.cfg_panelBorder
            from: 1
            to: 8
            value: page.cfg_panelBorderWidth
            suffix: "px"
            onEdited: function(v) { page.cfg_panelBorderWidth = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Shadow:"
            text: "Show a shadow"
            checked: page.cfg_panelShadow
            onToggled: page.cfg_panelShadow = checked
        }
        ColorField {
            visible: page.cfg_panelShadow
            recent: page.recentList
            value: page.cfg_panelShadowColor
            onPicked: function(h) { page.setColor("panelShadowColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Shadow blur:"
            visible: page.cfg_panelShadow
            from: 0
            to: 100
            value: page.cfg_panelShadowBlur
            suffix: "%"
            onEdited: function(v) { page.cfg_panelShadowBlur = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Window:"
            text: "Use the classic Plasma popup"
            checked: page.cfg_classicPopup
            onToggled: page.cfg_classicPopup = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "A fallback in case the normal popup misbehaves on your system. Normally not needed."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Button Corner Radius ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Button Corner Radius" }
        SliderField {
            Kirigami.FormData.label: "Slider bars:"
            value: page.cfg_sliderRadius
            to: 30
            suffix: "px"
            onEdited: function(v) { page.cfg_sliderRadius = v }
        }
        SliderField {
            Kirigami.FormData.label: "Large buttons:"
            value: page.cfg_largeRadius
            to: 30
            suffix: "px"
            onEdited: function(v) { page.cfg_largeRadius = v }
        }
        SliderField {
            Kirigami.FormData.label: "Small buttons:"
            value: page.cfg_smallRadius
            to: 30
            suffix: "px"
            onEdited: function(v) { page.cfg_smallRadius = v }
        }
        SliderField {
            Kirigami.FormData.label: "Media banner:"
            value: page.cfg_mediaRadius
            to: 30
            suffix: "px"
            onEdited: function(v) { page.cfg_mediaRadius = v }
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "The Wi-Fi, Bluetooth, Picker and Sound pages use the radius of the button that opened them."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Button and Slider Colors ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Button and Slider Colors" }
        QQC2.CheckBox {
            Kirigami.FormData.label: "On color:"
            text: "Use the brightest shade of my Plasma accent color"
            checked: page.cfg_useAccent
            onToggled: page.cfg_useAccent = checked
        }
        ColorField {
            enabled: !page.cfg_useAccent
            opacity: enabled ? 1.0 : 0.4
            recent: page.recentList
            value: page.cfg_onColor
            onPicked: function(h) { page.setColor("onColor", h) }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Off color:"
            text: "Use a dark shade of my Plasma accent color"
            checked: page.cfg_useAccentOff
            onToggled: page.cfg_useAccentOff = checked
        }
        ColorField {
            enabled: !page.cfg_useAccentOff
            opacity: enabled ? 1.0 : 0.4
            recent: page.recentList
            value: page.cfg_offColor
            onPicked: function(h) { page.setColor("offColor", h) }
        }
        QQC2.Button {
            visible: page.cfg_followSystem && page.cfg_offColorCustom && !page.cfg_useAccentOff
            text: "Off color: go back to following the system"
            icon.name: "edit-undo"
            onClicked: page.cfg_offColorCustom = false
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Border color:"
            text: "Show a border"
            checked: page.cfg_btnBorder
            onToggled: page.cfg_btnBorder = checked
        }
        ColorField {
            visible: page.cfg_btnBorder
            recent: page.recentList
            value: page.cfg_btnBorderColor
            onPicked: function(h) { page.setColor("btnBorderColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Border width:"
            visible: page.cfg_btnBorder
            from: 1
            to: 8
            value: page.cfg_btnBorderWidth
            suffix: "px"
            onEdited: function(v) { page.cfg_btnBorderWidth = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Shadow color:"
            text: "Show a shadow"
            checked: page.cfg_btnShadow
            onToggled: page.cfg_btnShadow = checked
        }
        ColorField {
            visible: page.cfg_btnShadow
            recent: page.recentList
            value: page.cfg_btnShadowColor
            onPicked: function(h) { page.setColor("btnShadowColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Shadow blur:"
            visible: page.cfg_btnShadow
            from: 0
            to: 100
            value: page.cfg_btnShadowBlur
            suffix: "%"
            onEdited: function(v) { page.cfg_btnShadowBlur = v }
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            visible: page.cfg_useAccent || page.cfg_useAccentOff
            text: "Both accent shades come from your Plasma accent color. In dark mode the dark shade is kept a little lighter than the panel so the buttons do not melt into it. To make the accent follow your wallpaper: System Settings > Colors & Themes > Colors > Accent color > From wallpaper."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Media banner ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Media banner" }
        QQC2.ComboBox {
            id: mediaMode
            Kirigami.FormData.label: "Color:"
            readonly property var ids: ["off", "on", "coverDark", "coverLight", "custom"]
            Layout.preferredWidth: 280
            model: ["Same as the off-state buttons", "Same as the lit buttons", "Album cover accent - dark", "Album cover accent - light", "Custom color"]
            currentIndex: Math.max(0, ids.indexOf(page.cfg_mediaColorMode))
            onActivated: function(i) { page.cfg_mediaColorMode = ids[i] }
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Album cover accent: the banner takes a calm shade of the cover's main color (dark, or light) and the progress bar a clearly different shade of the same color, so the bar stays visible."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        ColorField {
            Kirigami.FormData.label: "Custom color:"
            enabled: page.cfg_mediaColorMode === "custom"
            opacity: enabled ? 1.0 : 0.4
            recent: page.recentList
            value: page.cfg_mediaColor
            onPicked: function(h) { page.setColor("mediaColor", h) }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Border color:"
            text: "Show a border"
            checked: page.cfg_mediaBorder
            onToggled: page.cfg_mediaBorder = checked
        }
        ColorField {
            visible: page.cfg_mediaBorder
            recent: page.recentList
            value: page.cfg_mediaBorderColor
            onPicked: function(h) { page.setColor("mediaBorderColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Border width:"
            visible: page.cfg_mediaBorder
            from: 1
            to: 8
            value: page.cfg_mediaBorderWidth
            suffix: "px"
            onEdited: function(v) { page.cfg_mediaBorderWidth = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Shadow color:"
            text: "Show a shadow"
            checked: page.cfg_mediaShadow
            onToggled: page.cfg_mediaShadow = checked
        }
        ColorField {
            visible: page.cfg_mediaShadow
            recent: page.recentList
            value: page.cfg_mediaShadowColor
            onPicked: function(h) { page.setColor("mediaShadowColor", h) }
        }
        SliderField {
            Kirigami.FormData.label: "Shadow blur:"
            visible: page.cfg_mediaShadow
            from: 0
            to: 100
            value: page.cfg_mediaShadowBlur
            suffix: "%"
            onEdited: function(v) { page.cfg_mediaShadowBlur = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "When idle:"
            text: "Keep the banner visible when nothing is playing"
            checked: page.cfg_mediaShowIdle
            onToggled: page.cfg_mediaShowIdle = checked
        }
    }
}
