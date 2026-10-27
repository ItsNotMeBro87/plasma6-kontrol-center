import QtQuick

// Text that is cut off with "..." when it does not fit, and scrolls from right to left while the mouse is over it
// (or over `forceHover`, e.g. the whole button), so the full text can be read.
Item {
    id: m
    property string text: ""
    property color color: "white"
    property alias font: lbl.font
    property int horizontalAlignment: Text.AlignLeft
    property int style: Text.Normal
    property color styleColor: "transparent"
    property bool forceHover: false
    readonly property bool overflow: lbl.implicitWidth > m.width + 0.5
    readonly property bool scrolling: (hh.hovered || forceHover) && overflow

    implicitWidth: lbl.implicitWidth
    implicitHeight: lbl.implicitHeight
    clip: true

    Text {
        id: lbl
        text: m.text
        color: m.color
        textFormat: Text.PlainText
        style: m.style
        styleColor: m.styleColor
        horizontalAlignment: m.horizontalAlignment
        width: m.scrolling ? implicitWidth : m.width
        elide: m.scrolling ? Text.ElideNone : Text.ElideRight
    }
    HoverHandler { id: hh }

    SequentialAnimation {
        running: m.scrolling
        loops: Animation.Infinite
        PauseAnimation { duration: 350 }
        NumberAnimation {
            target: lbl; property: "x"
            to: -(lbl.implicitWidth - m.width) - 4
            duration: Math.max(900, (lbl.implicitWidth - m.width) * 28)
        }
        PauseAnimation { duration: 700 }
        NumberAnimation { target: lbl; property: "x"; to: 0; duration: 250 }
    }
    onScrollingChanged: if (!scrolling) lbl.x = 0
}
