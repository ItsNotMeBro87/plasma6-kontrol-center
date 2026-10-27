import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// A one-color icon that stays readable on a see-through panel (soft contrasting shadow around it).
Item {
    id: hi
    property var theme
    property url source
    property color color: "white"
    property real iconOpacity: 1.0
    implicitWidth: 24
    implicitHeight: 24

    Kirigami.Icon {
        id: base
        anchors.fill: parent
        source: hi.source
        isMask: true
        color: hi.color
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.fill: base
        source: base
        opacity: hi.iconOpacity
        shadowEnabled: hi.theme ? hi.theme.legible : false
        shadowColor: hi.theme ? hi.theme.haloColor : "black"
        shadowOpacity: 1.0
        shadowBlur: 0.6
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowScale: 1.12
    }
}
