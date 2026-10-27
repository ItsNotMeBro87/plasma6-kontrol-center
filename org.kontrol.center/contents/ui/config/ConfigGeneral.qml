import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import "../Presets.js" as Presets
import "../Strings.js" as Strings

KCMUtils.SimpleKCM {
    id: page

    property string cfg_panelIcon
    property string cfg_panelIconDefault
    property bool cfg_panelIconKeepColors
    property bool cfg_panelIconKeepColorsDefault
    property bool cfg_showDate
    property bool cfg_showDateDefault
    property string cfg_dateFormat
    property string cfg_dateFormatDefault
    property bool cfg_showUptime
    property bool cfg_showUptimeDefault
    property string cfg_language
    property string cfg_languageDefault

    function langIndex() {
        for (var i = 0; i < Strings.languages.length; i++) if (Strings.languages[i].id === cfg_language) return i
        return 0
    }
    function dateIndex() {
        for (var i = 0; i < Presets.dateFormats.length; i++) if (Presets.dateFormats[i].id === cfg_dateFormat) return i
        return 0
    }

    Kirigami.FormLayout {

        // ---------------- Widget icon ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Widget icon" }
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
            text: "This is the icon shown on your panel. Only the panel icon keeps its colors; button icons inside the popup are always flat, one-color icons. Turn this off for a one-color SVG (like the Tabler icons) so it is tinted like your panel text."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Header ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Header" }
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
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "The power, restart, log out and lock buttons on the right of the header are always shown."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        // ---------------- Language ----------------
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Language" }
        QQC2.ComboBox {
            Kirigami.FormData.label: "Language:"
            Layout.preferredWidth: 260
            textRole: "label"
            model: Strings.languages
            currentIndex: page.langIndex()
            onActivated: function(i) { page.cfg_language = Strings.languages[i].id }
        }
        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Changes the texts and the date in the popup. These settings windows stay in English. The translations were written by hand and by Claude: if one reads oddly, please tell us on GitHub."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
    }
}
