import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs

// Colour chooser: 3 rows of 12 swatches (recent / dark / light), a colour dialog and a hex code box.
ColumnLayout {
    id: cf
    property string value: "#000000"
    property var recent: []          // newest first, filled gradually (max 12), shared by every colour field
    signal picked(string hex)

    readonly property var darkSwatches: [
        "#000000", "#111318", "#1b1b1f", "#232629", "#292c30", "#2b2d42",
        "#1f2d3d", "#2d2433", "#1f2d26", "#3a2a2a", "#33302a", "#4a4a4a"
    ]
    readonly property var lightSwatches: [
        "#ffffff", "#f7f7f7", "#eff0f1", "#d9d9d9", "#a6a6a6", "#dfe7fd",
        "#e2ece9", "#fde2e4", "#fff1e6", "#e9d8fd", "#d4f1f4", "#f6e7a8"
    ]

    spacing: 6
    RowLayout {
        spacing: 8
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 4
            color: cf.value
            border.width: 1
            border.color: "#80808080"
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dlg.open() }
        }
        Binding { target: hex; property: "text"; value: cf.value }
        QQC2.TextField {
            id: hex
            Layout.preferredWidth: 100
            maximumLength: 7
            placeholderText: "#rrggbb"
            validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
            onEditingFinished: if (acceptableInput) cf.picked(text.toLowerCase())
        }
        QQC2.Button {
            text: "Pick any color..."
            icon.name: "color-management"
            onClicked: dlg.open()
        }
    }

    component SwatchRow: RowLayout {
        id: sr
        property string title: ""
        property var colors: []      // up to 12 entries; "" = empty slot
        property string cur: ""
        signal chosen(string c)
        spacing: 8
        QQC2.Label {
            text: sr.title
            opacity: 0.7
            font.pixelSize: 11
            Layout.preferredWidth: 44
        }
        Row {
            spacing: 4
            Repeater {
                model: 12
                delegate: Rectangle {
                    readonly property string c: index < sr.colors.length ? String(sr.colors[index]) : ""
                    width: 22; height: 22; radius: 3
                    color: c !== "" ? c : "transparent"
                    readonly property bool current: c !== "" && sr.cur.toLowerCase() === c.toLowerCase()
                    border.width: current ? 2 : 1
                    border.color: current ? "#ffffff" : (c !== "" ? "#80808080" : "#30808080")
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.c !== ""
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sr.chosen(parent.c)
                    }
                }
            }
        }
    }

    SwatchRow { title: "Recent"; colors: cf.recent; cur: cf.value; onChosen: function(c) { cf.picked(c) } }
    SwatchRow { title: "Dark"; colors: cf.darkSwatches; cur: cf.value; onChosen: function(c) { cf.picked(c) } }
    SwatchRow { title: "Light"; colors: cf.lightSwatches; cur: cf.value; onChosen: function(c) { cf.picked(c) } }

    ColorDialog {
        id: dlg
        selectedColor: cf.value
        onAccepted: cf.picked(selectedColor.toString())
    }
}
