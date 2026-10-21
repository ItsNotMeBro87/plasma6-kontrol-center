import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// Slider + number box kept in sync. 0 = boxy / none.
RowLayout {
    id: f
    property int value: 0
    property int from: 0
    property int to: 100
    property string suffix: ""
    signal edited(int v)

    spacing: 8
    QQC2.Slider {
        id: sl
        Layout.preferredWidth: 220
        from: f.from
        to: f.to
        stepSize: 1
        onMoved: f.edited(Math.round(value))
    }
    Binding { target: sl; property: "value"; value: f.value }
    QQC2.SpinBox {
        id: sb
        from: f.from
        to: f.to
        editable: true
        onValueModified: f.edited(value)
    }
    Binding { target: sb; property: "value"; value: f.value }
    QQC2.Label { text: f.suffix; visible: f.suffix !== "" }
}
