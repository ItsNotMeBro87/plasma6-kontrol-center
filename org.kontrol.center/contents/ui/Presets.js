.pragma library
// Shared catalogue of button types. Used by the widget and by the settings pages.

var catalog = [
  { id: "wifi",       label: "Wi-Fi",         icon: "wifi.svg",          iconOff: "wifi-off.svg",          page: "wifi" },
  { id: "bluetooth",  label: "Bluetooth",     icon: "kc-bluetooth.svg",  iconOff: "bluetooth-off.svg",     page: "bluetooth" },
  { id: "pen",        label: "Pen Display",   icon: "device-tablet.svg", iconOff: "device-tablet-off.svg" },
  { id: "profile",    label: "Power Profile", icon: "scale.svg" },
  { id: "dnd",        label: "DND",           icon: "bell-off.svg",      iconOff: "kc-bell.svg" },
  { id: "caffeine",   label: "Caffeine",      icon: "coffee.svg" },
  { id: "night",      label: "Night",         icon: "bulb.svg" },
  { id: "dark",       label: "Dark",          icon: "moon.svg" },
  { id: "headset",    label: "Headset",       icon: "headphones.svg",    iconOff: "headphones-off.svg" },
  { id: "cloudflare", label: "Cloudflare",    icon: "cloud.svg",         iconOff: "cloud-off.svg" },
  { id: "airplane",   label: "Airplane",      icon: "plane.svg" },
  { id: "capture",    label: "Capture",       icon: "kc-camera.svg" },
  { id: "record",     label: "Record",        icon: "kc-video.svg" },
  { id: "mic",        label: "Mic",           icon: "microphone.svg",    iconOff: "microphone-off.svg" },
  { id: "picker",     label: "Picker",        icon: "color-picker.svg",  page: "picker" },
  { id: "custom",     label: "Custom",        icon: "terminal-2.svg" }
]

// Date formats for the header (Qt format strings). "full" is the original look.
var dateFormats = [
  { id: "full",     label: "Full - Tuesday, 20 October 2026",       fmt: "dddd, d MMMM yyyy" },
  { id: "full-us",  label: "Full (US) - Tuesday, October 20, 2026", fmt: "dddd, MMMM d, yyyy" },
  { id: "iso",      label: "ISO 8601 - 2026-10-20",                 fmt: "yyyy-MM-dd" },
  { id: "iso-day",  label: "ISO 8601 + day - Tue 2026-10-20",       fmt: "ddd yyyy-MM-dd" },
  { id: "eu",       label: "Europe (DMY) - 20/10/2026",             fmt: "dd/MM/yyyy" },
  { id: "de",       label: "Germany / Russia (DMY, dots) - 20.10.2026", fmt: "dd.MM.yyyy" },
  { id: "us",       label: "USA (MDY) - 10/20/2026",                fmt: "MM/dd/yyyy" },
  { id: "asia",     label: "Japan / China / Korea (YMD) - 2026/10/20", fmt: "yyyy/MM/dd" },
  { id: "short",    label: "Short - Tue, 20 Oct",                   fmt: "ddd, d MMM" },
  { id: "day",      label: "Day name only - Tuesday",               fmt: "dddd" }
]
function dateFormatOf(id) {
    for (var i = 0; i < dateFormats.length; i++) if (dateFormats[i].id === id) return dateFormats[i].fmt
    return dateFormats[0].fmt
}

// BlueZ "Icon" value (+ the device name as a hint) -> bundled icon file
function btIcon(icon, name) {
    var i = String(icon || ""), n = String(name || "").toLowerCase()
    if (i.indexOf("audio-headset") === 0 || i.indexOf("audio-headphones") === 0 || /headset|headphone|buds|airpods|earphone|earbud|wh-|wf-/.test(n)) return "headphones.svg"
    if (i.indexOf("input-keyboard") === 0 || /keyboard/.test(n)) return "keyboard.svg"
    if (i.indexOf("input-mouse") === 0 || /mouse|trackball|trackpad/.test(n)) return "mouse.svg"
    if (i.indexOf("input-gaming") === 0 || /controller|gamepad|joy-?con|dualsense|dualshock|xbox/.test(n)) return "device-gamepad-2.svg"
    if (i.indexOf("input-tablet") === 0 || /tablet|pen/.test(n)) return "device-tablet.svg"
    if (i.indexOf("phone") === 0 || /phone|iphone|galaxy|pixel|redmi|xiaomi|oppo|vivo/.test(n)) return "device-mobile.svg"
    if (i.indexOf("computer") === 0 || /laptop|notebook|macbook|thinkpad/.test(n)) return "device-laptop.svg"
    if (i.indexOf("audio-speakers") === 0 || i.indexOf("audio-card") === 0 || /speaker|soundbar|boombox|jbl|bose|echo|homepod/.test(n)) return "device-speaker.svg"
    if (/watch|band|fit/.test(n)) return "device-watch.svg"
    if (i.indexOf("printer") === 0 || /printer/.test(n)) return "printer.svg"
    if (i.indexOf("video-display") === 0 || /\btv\b|bravia|chromecast|monitor/.test(n)) return "device-tv.svg"
    if (i.indexOf("camera") === 0) return "camera.svg"
    if (i.indexOf("microphone") === 0 || /\bmic\b/.test(n)) return "microphone.svg"
    return "kc-bluetooth.svg"
}

function find(id) {
    for (var i = 0; i < catalog.length; i++) if (catalog[i].id === id) return catalog[i]
    return null
}
function labelOf(entry) {
    if (entry.label) return entry.label
    var c = find(entry.preset)
    return c ? c.label : "Custom"
}
function defaultIconFile(id) { var c = find(id); return c ? c.icon : "terminal-2.svg" }
function indexOfPreset(id) {
    for (var i = 0; i < catalog.length; i++) if (catalog[i].id === id) return i
    return catalog.length - 1
}
// spec: "" | "theme:name" | "/absolute/path.svg" | "file.svg" (bundled icons folder) | plain theme name
function iconUrl(spec, base) {
    if (!spec) return ""
    if (spec.indexOf("theme:") === 0) return spec.substring(6)
    if (spec.charAt(0) === "/") return "file://" + spec
    if (spec.indexOf(".svg") > 0) return base + spec
    return spec
}
function defaultEntry(id, size) {
    var e = { preset: id, size: size, label: "", icon: "", cmdOn: "", cmdOff: "", arg: "", uid: "" }
    // Pen Display and Headset need YOUR own toggle script (set it in the button editor); left blank on purpose
    if (id === "pen") e.arg = "HDMI-A-1"
    if (id === "custom") {
        e.label = "Custom"; e.icon = "terminal-2.svg"
        e.cmdOn = "notify-send 'Custom' 'ON'"; e.cmdOff = "notify-send 'Custom' 'OFF'"
        e.uid = "c" + Date.now() + Math.floor(Math.random() * 1000)
    }
    return e
}
var defaultButtonsJson = "[{\"preset\":\"wifi\",\"size\":\"large\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"bluetooth\",\"size\":\"large\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"airplane\",\"size\":\"large\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"profile\",\"size\":\"large\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"dnd\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"caffeine\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"night\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"dark\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"mic\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"cloudflare\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"capture\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"record\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"picker\",\"size\":\"small\",\"label\":\"\",\"icon\":\"\",\"cmdOn\":\"\",\"cmdOff\":\"\",\"arg\":\"\",\"uid\":\"\"},{\"preset\":\"custom\",\"size\":\"small\",\"label\":\"Custom\",\"icon\":\"terminal-2.svg\",\"cmdOn\":\"notify-send 'Custom 1' 'ON'\",\"cmdOff\":\"notify-send 'Custom 1' 'OFF'\",\"arg\":\"\",\"uid\":\"c1\"},{\"preset\":\"custom\",\"size\":\"small\",\"label\":\"Custom\",\"icon\":\"terminal-2.svg\",\"cmdOn\":\"notify-send 'Custom 2' 'ON'\",\"cmdOff\":\"notify-send 'Custom 2' 'OFF'\",\"arg\":\"\",\"uid\":\"c2\"}]"
var defaultOrder = "brightness,volume,large,small,media"
