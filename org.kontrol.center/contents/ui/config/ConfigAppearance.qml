import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page

    property string cfg_panelIcon
    property string cfg_panelIconDefault
    property bool cfg_classicPopup
    property bool cfg_classicPopupDefault
    property int cfg_panelRadius
    property int cfg_panelRadiusDefault
    property string cfg_panelColor
    property string cfg_panelColorDefault
    property bool cfg_panelTransparent
    property bool cfg_panelTransparentDefault
    property int cfg_panelTransparency
    property int cfg_panelTransparencyDefault
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
    property bool cfg_followSystem
    property bool cfg_followSystemDefault
    property int cfg_panelBlur
    property int cfg_panelBlurDefault
    property bool cfg_blurKwin
    property bool cfg_blurKwinDefault
    property bool cfg_panelIconKeepColors
    property bool cfg_panelIconKeepColorsDefault
    property string cfg_recentColors
    property string cfg_recentColorsDefault
    property string cfg_mediaColorMode
    property string cfg_mediaColorModeDefault
    property string cfg_mediaColor
    property string cfg_mediaColorDefault
    property bool cfg_mediaShowIdle
    property bool cfg_mediaShowIdleDefault

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

        // ---------------- Widget icon ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Widget icon (shown on your panel)" }
        IconField {
            Kirigami.FormData.label: "Icon:"
            value: page.cfg_panelIcon
            placeholder: "kc-gear.svg  (colorful gear)"
            onPicked: function(v) { page.cfg_panelIcon = (v === "" ? "kc-gear.svg" : v) }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: ""
            text: "Keep the colors of an SVG icon on the panel"
            checked: page.cfg_panelIconKeepColors
            onToggled: page.cfg_panelIconKeepColors = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Only the panel icon keeps its colors. Button icons inside the popup are always flat, one-color icons. Turn this off for a one-color SVG (like the Tabler icons) so it is tinted like your panel text."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Panel ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Panel" }
        SliderField {
            Kirigami.FormData.label: "Corner radius:"
            value: page.cfg_panelRadius
            to: 40
            suffix: "px  (0 = boxy)"
            onEdited: function(v) { page.cfg_panelRadius = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Colors:"
            text: "Follow system light / dark mode (panel color; Off buttons too until you pick your own)"
            checked: page.cfg_followSystem
            onToggled: page.cfg_followSystem = checked
        }
        ColorField {
            Kirigami.FormData.label: "Panel color:"
            enabled: !page.cfg_followSystem
            opacity: enabled ? 1.0 : 0.4
            recent: page.recentList
            value: page.cfg_panelColor
            onPicked: function(h) { page.setColor("panelColor", h) }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Background:"
            text: "Transparent (see-through)"
            checked: page.cfg_panelTransparent
            onToggled: page.cfg_panelTransparent = checked
        }
        SliderField {
            Kirigami.FormData.label: "Transparency:"
            enabled: page.cfg_panelTransparent
            value: page.cfg_panelTransparency
            to: 100
            suffix: "%  (100 = buttons float, 0 = solid)"
            onEdited: function(v) { page.cfg_panelTransparency = v }
        }
        SliderField {
            Kirigami.FormData.label: "Blur:"
            value: page.cfg_panelBlur
            to: 100
            suffix: "%  (0 = no blur)"
            onEdited: function(v) { page.cfg_panelBlur = v }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: ""
            enabled: page.cfg_panelBlur > 0
            text: "Also use this value as KWin's blur strength (affects ALL blurred windows)"
            checked: page.cfg_blurKwin
            onToggled: page.cfg_blurKwin = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            visible: page.cfg_panelBlur > 0
            text: "Blur is drawn by KWin behind Plasma's own frame, so it needs the Blur desktop effect to be enabled and a see-through panel (if Transparent is off, the panel is made 28% see-through automatically). KWin has no per-widget blur strength: the amount of blur is a system-wide setting (System Settings > Desktop Effects > Blur), which is why changing it from here is optional."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Window:"
            text: "Use the classic Plasma popup (fallback - normally not needed)"
            checked: page.cfg_classicPopup
            onToggled: page.cfg_classicPopup = checked
        }

        // ---------------- Button shapes ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Button shapes (0 = boxy, higher = rounder)" }
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
            suffix: "px  (24 = round)"
            onEdited: function(v) { page.cfg_smallRadius = v }
        }
        SliderField {
            Kirigami.FormData.label: "Media banner:"
            value: page.cfg_mediaRadius
            to: 30
            suffix: "px"
            onEdited: function(v) { page.cfg_mediaRadius = v }
        }

        // ---------------- Button colors ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Button colors (also used by the slider bars)" }
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
        QQC2.Label {
            Kirigami.FormData.label: ""
            visible: page.cfg_useAccent || page.cfg_useAccentOff
            text: "Both shades come from your Plasma accent color. In dark mode the dark shade is kept a little lighter than the panel so the buttons do not melt into it. To make the accent follow your wallpaper: System Settings > Colors & Themes > Colors > Accent color > From wallpaper."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Media banner ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Media banner" }
        QQC2.ComboBox {
            id: mediaMode
            Kirigami.FormData.label: "Color:"
            readonly property var ids: ["off", "on", "custom"]
            model: ["Same as the off-state buttons", "Same as the lit buttons", "Custom color"]
            currentIndex: Math.max(0, ids.indexOf(page.cfg_mediaColorMode))
            onActivated: function(i) { page.cfg_mediaColorMode = ids[i] }
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
            Kirigami.FormData.label: "When idle:"
            text: "Keep the banner visible when nothing is playing"
            checked: page.cfg_mediaShowIdle
            onToggled: page.cfg_mediaShowIdle = checked
        }
    }
}
