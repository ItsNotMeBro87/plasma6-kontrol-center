import QtQuick

// Turns the saved settings (+ the system colours) into the colours and sizes the widget uses.
QtObject {
    id: t
    property var conf                 // Plasmoid.configuration
    property string systemAccent: ""  // "#rrggbb" read from kdeglobals (wallpaper accent), or ""
    property color sysBg: "#292c30"   // current colour scheme (changes live with dark/light mode)
    property color sysText: "#fcfcfc"
    property color sysHighlight: "#3daee9"

    // one spacing value used for the panel padding AND the gaps between every row/column
    readonly property int gap: 12

    function lum(c) { return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b }
    function inkFor(c) { return lum(c) > 0.62 ? "#1b1b1b" : "#ffffff" }
    // same hue as c, with a chosen lightness
    function tone(c, light, satMul) {
        var grey = c.hslHue < 0
        return Qt.hsla(grey ? 0 : c.hslHue, grey ? 0 : Math.min(1, c.hslSaturation * satMul), light, 1)
    }

    // ---- accent: wallpaper accent if Plasma provides it, otherwise the live highlight colour
    readonly property color accent: systemAccent !== "" ? systemAccent : sysHighlight
    readonly property color brightAccent: tone(accent, Math.max(accent.hslLightness, 0.55), 1.0)
    // "dark" accent for the Off buttons. On a dark panel the very darkest shade melts into the panel, so it is
    // kept a little lighter than the panel itself (but still much darker than the bright accent).
    readonly property color darkAccent: {
        var pl = panelBase.hslLightness
        var l = pl < 0.5 ? Math.min(0.42, Math.max(0.24, pl + 0.15)) : 0.22
        return tone(accent, Math.min(accent.hslLightness, l), 0.7)
    }

    // ---- panel
    readonly property bool follow: conf.followSystem
    // Blur needs Plasma's own frame (KWin only blurs behind that), and it is only visible through a see-through panel.
    readonly property bool blur: conf.panelBlur > 0
    // 1 = solid, 0 = invisible. "Transparent" sets the amount; with Blur on and Transparent off the panel
    // is made slightly see-through (28%) automatically, otherwise the blur could not be seen at all.
    readonly property real opacityPanel: conf.panelTransparent ? 1 - conf.panelTransparency / 100 : (blur ? 0.72 : 1)
    readonly property color panelBase: follow ? sysBg : conf.panelColor
    readonly property color panel: Qt.rgba(panelBase.r, panelBase.g, panelBase.b, opacityPanel)
    readonly property color textOnPanel: inkFor(panelBase)
    readonly property int panelRadius: conf.panelRadius

    // ---- buttons
    readonly property color sysInk: inkFor(sysBg)
    readonly property color followOff: Qt.tint(sysBg, Qt.rgba(sysInk.r, sysInk.g, sysInk.b, 0.12))
    // Off colour: accent shade, or your own colour; when "follow system" is on and you have not picked one, it follows the system
    readonly property color offColor: conf.useAccentOff ? darkAccent : ((follow && !conf.offColorCustom) ? followOff : conf.offColor)
    readonly property color litColor: conf.useAccent ? brightAccent : conf.onColor
    readonly property color textOnOff: inkFor(offColor)
    readonly property color textOnOn: inkFor(litColor)

    // ---- shapes
    readonly property int sliderRadius: conf.sliderRadius
    readonly property int largeRadius: conf.largeRadius
    readonly property int smallRadius: conf.smallRadius
    readonly property int mediaRadius: conf.mediaRadius

    // ---- media banner: same as off colour, same as lit colour, or any custom colour
    readonly property color mediaColor: conf.mediaColorMode === "on" ? litColor
                                        : (conf.mediaColorMode === "custom" ? conf.mediaColor : offColor)
    readonly property color textOnMedia: inkFor(mediaColor)
    readonly property color mediaTrack: Qt.tint(mediaColor, Qt.rgba(textOnMedia.r, textOnMedia.g, textOnMedia.b, 0.32))
}
