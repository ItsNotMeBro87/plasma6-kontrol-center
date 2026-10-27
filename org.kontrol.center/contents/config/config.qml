import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "Appearance"
        icon: "preferences-desktop-color"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: "Layout and Buttons"
        icon: "view-list-icons"
        source: "config/ConfigButtons.qml"
    }
    ConfigCategory {
        name: "Author"
        icon: "help-about"
        source: "config/ConfigAbout.qml"
    }
}
