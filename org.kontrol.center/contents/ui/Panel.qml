import QtQuick

// Scales the whole control center (panel, buttons, sliders, banner, texts) by the "Scale" setting.
// PanelBody is laid out at 100 %; this wrapper reports the scaled size to the popup window.
Item {
    id: wrap
    property var ctl
    readonly property real k: ctl.conf.panelScale / 100
    implicitWidth: body.implicitWidth * k
    implicitHeight: body.implicitHeight * k

    PanelBody {
        id: body
        ctl: wrap.ctl
        width: implicitWidth
        height: implicitHeight
        scale: wrap.k
        transformOrigin: Item.TopLeft
    }
}
