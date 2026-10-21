import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

// Popup window. Loaded by main.qml; if this file cannot load, main.qml falls back to the classic popup.
//
// - type AppletPopup: the same window type Plasma uses for its own widgets, so the window is placed with
//   the normal floating gap and KWin effects (rounded corners, outlines) treat it like every other widget.
// - normal mode: no Plasma frame, the panel draws its own rounded rectangle (+ a small transparent margin).
// - blur mode: Plasma's own frame is used, because that is what makes KWin blur the desktop behind it.
PlasmaCore.Dialog {
    id: dlg
    property var ctl: null
    property var panelComp: null
    property double closedAt: 0
    readonly property bool frameMode: ctl ? ctl.theme.blur : false

    visualParent: ctl
    location: ctl ? ctl.plasmoidLocation : PlasmaCore.Types.BottomEdge
    type: PlasmaCore.Dialog.AppletPopup
    hideOnWindowDeactivate: true
    backgroundHints: frameMode ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
    visible: false

    mainItem: Item {
        id: holder
        readonly property real pad: dlg.frameMode ? 0 : 8   // keeps the panel off the screen edge / bar

        implicitWidth: ld.implicitWidth + 2 * pad
        implicitHeight: ld.implicitHeight + 2 * pad
        // fixed to the content, so the window can never be smaller (clipped) or larger than the panel
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        Loader {
            id: ld
            x: holder.pad
            y: holder.pad
            width: implicitWidth
            height: implicitHeight
            active: dlg.panelComp !== null
            sourceComponent: dlg.panelComp
        }
    }

    function toggle() {
        if (visible) visible = false
        else if (Date.now() - closedAt > 250) visible = true
    }
    onVisibleChanged: if (!visible) closedAt = Date.now()
}
