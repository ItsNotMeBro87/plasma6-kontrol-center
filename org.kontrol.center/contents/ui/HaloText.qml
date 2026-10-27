import QtQuick

// Text that stays readable on a see-through panel: when the panel is see-through (and the option is on) the glyphs get a thin outline in the opposite shade.
Text {
    property var theme
    style: (theme && theme.legible) ? Text.Outline : Text.Normal
    styleColor: theme ? theme.haloColor : "transparent"
}
