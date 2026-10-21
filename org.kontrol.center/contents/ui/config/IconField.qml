import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes
import "../Presets.js" as Presets

// Icon chooser: pick a KDE theme icon, an SVG file, or type a name / path.
RowLayout {
    id: f
    property string value: ""
    property string placeholder: ""
    signal picked(string v)
    readonly property string base: Qt.resolvedUrl("../../icons/").toString()

    spacing: 6
    Kirigami.Icon {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        source: Presets.iconUrl(f.value, f.base)
        isMask: f.value.indexOf("theme:") !== 0
        color: Kirigami.Theme.textColor
    }
    Binding { target: txt; property: "text"; value: f.value }
    QQC2.TextField {
        id: txt
        Layout.preferredWidth: 200
        placeholderText: f.placeholder
        onEditingFinished: f.picked(text)
    }
    QQC2.Button {
        text: "Theme icon..."
        onClicked: themeDlg.open()
    }
    QQC2.Button {
        text: "SVG file..."
        onClicked: fileDlg.open()
    }
    QQC2.Button {
        text: "Default"
        visible: f.value !== ""
        onClicked: f.picked("")
    }
    KIconThemes.IconDialog {
        id: themeDlg
        onIconNameChanged: if (themeDlg.iconName !== "") f.picked("theme:" + themeDlg.iconName)
    }
    FileDialog {
        id: fileDlg
        title: "Choose an SVG icon"
        nameFilters: ["SVG icons (*.svg)", "All files (*)"]
        onAccepted: f.picked(decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")))
    }
}
