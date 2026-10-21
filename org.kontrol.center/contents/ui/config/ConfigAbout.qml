import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Kontrol Center" }
        QQC2.Label {
            Kirigami.FormData.label: "Description:"
            text: "A fully configurable control center for KDE Plasma: brightness for every screen, volume, network and system toggles, your own script buttons, a colour picker with history, and a media banner that works with any MPRIS player."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.Label { Kirigami.FormData.label: "Version:"; text: "0.7.5 Beta" }
        QQC2.Label {
            Kirigami.FormData.label: "Author:"
            text: "ItsNotMeBro87 (Agon A.)"
        }
        QQC2.Label {
            Kirigami.FormData.label: "Website:"
            text: "<a href=\"https://github.com/ItsNotMeBro87/plasma6-kontrol-center\">https://github.com/ItsNotMeBro87/plasma6-kontrol-center</a>"
            textFormat: Text.StyledText
            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WrapAnywhere
        }
        QQC2.Label {
            Kirigami.FormData.label: "Code:"
            text: "Written with Claude"
        }
        QQC2.Label { Kirigami.FormData.label: "License:"; text: "GNU General Public License v3.0 or later (GPL-3.0-or-later)" }
        QQC2.Label {
            Kirigami.FormData.label: "Icons:"
            text: "Tabler Icons (MIT) - downloaded by install.sh; Lucide (ISC) and a few hand-drawn outline icons as fallbacks. Their licenses are compatible with the GPL; see NOTICE.md."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
    }
}
