# Kontrol Center 0.7.7 Beta (changes over 0.7.5 Beta)

Pages inside the panel
- Wi-Fi, Bluetooth, Picker and Sound now open as pages inside Kontrol Center (header stays, Back button) instead
  of System Settings. Large buttons use the arrow; small buttons get an arrow badge in the bottom right corner.
  The badge has its own color (a shade of the Off color, it does not light up with the button) and a ring in the
  panel color, so it stays visible on round and boxy buttons, on or off. The button and the badge are separate
  click areas. Rows and boxes on the pages follow the corner radius of the button that opened them.
- An expansion page is never smaller than the normal panel (same total height); it only grows if it has more to show.
- Wi-Fi page: current connection (IP, signal, band), password prompt with show / hide, saved and available
  networks, forget, refresh, on / off. The label is now "Wi-Fi".
- Bluetooth page: connected / available devices with device icons, signal or battery %, connect / disconnect /
  remove, auto-reconnect (trusted) and address details, Discoverable switch, refresh, on / off, pairing requests
  (confirm code, authorize, PIN) through a small agent that runs only while the page is open (bt-agent.py).
- The refresh icon spins while a Wi-Fi or Bluetooth refresh is really running and stops when it is done. The
  switches and the refresh icon in the page bar are 20% smaller.
- Picker page: last 20 colors (a repeated color moves to the front), click to copy, per-color delete, clear all.
  The "Recent" row under the small buttons is gone.
- Sound page: Hardware tab (default device, port per device, volume and mute) and Applications tab (volume and
  mute per application). Microphone is not included. The sliders follow clicks and the mouse wheel at once.

Settings
- New General page (widget icon, header options, language).
- Languages: English (default), Bahasa Indonesia, Deutsch, Español, Français, 日本語, Português, 한국어, Русский,
  中文 (简体) and العربية (right-to-left layout). Long texts in the popup are translated too.
- Appearance: panel width and a new **Scale** (enlarges or shrinks the whole widget); border and shadow (color,
  border width, shadow blur) for the panel, buttons / sliders and media banner; the Transparent checkbox is
  removed (the slider alone decides); media banner colors are: same as the off-state buttons, same as the lit
  buttons, album cover accent - dark, album cover accent - light, custom; hints such as "(0 = boxy)" were removed
  or moved below the option; "Button shapes" is now "Button Corner Radius" and "Button colors" is "Button and
  Slider Colors".
- Layout and Buttons > Behavior now explains the Dark / Light color scheme boxes, how to list scheme names
  (`plasma-apply-colorscheme --list-schemes`) and what to expect from third-party schemes and Kvantum.
- Profiles can be saved as layout only or layout with current colors.

Other
- Text that does not fit scrolls from right to left while the mouse is over it (button names and status such as
  "On - Not connected", song / artist / album, network and device names).
- Scroll arrows under the header and at the bottom appear when the content is taller than the screen.
- Text and icons stay readable on a see-through panel (optional outline / halo).
- Fix: the Bluetooth icon is now a hand-drawn glyph (kc-bluetooth.svg) that the icon downloader never replaces.
- Fix: leaving airplane mode no longer switches Bluetooth on; Wi-Fi and Bluetooth return to the state they had
  before airplane mode. Wi-Fi, Bluetooth and airplane mode are restored after login (airplane.sh, restore.sh).
- Blur: still a system-wide KWin setting; labels and help text clarified.

# Kontrol Center 0.7.5 Beta (changes over 0.7.4 Beta) - first public release

- Default layout: Pen Display and Headset are no longer in it (Airplane now sits in the large row and Mic
  replaces Headset). Both buttons can still be added from the settings; their toggle scripts are blank and
  must be set by the user.
- About page: website link (https://github.com/ItsNotMeBro87/plasma6-kontrol-center).
- Author is now "ItsNotMeBro87 (Agon A.)".
- Added README.md and check-deps.sh.

# Kontrol Center 0.7.4 Beta (changes over 0.7.3 Beta)

Main widget
- Color picker fixed at the root: it now asks KWin's own picker (one blocking D-Bus call). The desktop portal
  answers with a signal that a short-lived command never receives, which is why nothing was recorded and a
  second try did nothing. Fallbacks: portal with a persistent connection, then KColorChooser.
  Every run is unique, and a stuck run is stopped by the next click.
- Recent colors: one slim row of 7 small swatches under the buttons; click a swatch to copy its hex code.
- Bluetooth button: Off / On - Not connected / Connected (N devices).
- New Mic button (hidden when no microphone is connected): mute / unmute the default input.

Appearance
- "Follow system light/dark" now disables only the panel color. On and Off colors can always be chosen.
- Dark accent shade for Off buttons is kept a bit lighter than the panel in dark mode.

Layout and Buttons (renamed from Buttons)
- Show / hide day and date, 10 date formats (ISO 8601, EU, US, Japan/China/Korea, German, ...).
- Show / hide uptime.
- Profiles: save and load the layout and buttons as files in ~/.local/share/kontrol-center/profiles.
- Media player filter accepts several players separated by commas (ytm, spotify), with a description.

Author / About / License
- Version 0.7.4 Beta; code credit "Written with Claude".
- License changed from MIT to GPL-3.0-or-later (LICENSE and NOTICE.md added).

# Kontrol Center 0.7.3 Beta (changes over 0.7.2 Beta)

Main widget
- Colour picker rewritten (picker.sh): the portal reply is now read line-buffered and matched to our own request,
  so picks no longer get lost. After a pick the popup comes back with the history open (before, the history
  panel was closed again every time the popup re-opened, so it looked empty). History keeps the last 12 colours.
- Wi-Fi button has 3 states: Off / On / <network name> (SSID) when connected.

Appearance
- Default panel icon is a colourful gear (kc-gear.svg). An SVG chosen as panel icon keeps its colours on the
  panel ("Keep the colors of an SVG icon" can be turned off). Button icons stay flat, one-colour icons.
- Translucent removed. New Blur slider (0-100 %). Transparent is unchanged. Optional: also use the slider as
  KWin's system-wide blur strength (off by default).
- Colour chooser: 3 rows of 12 swatches (recent / dark / light) + colour dialog + hex box.

Buttons
- Brightness and Volume are separate parts and can be dragged to any position.
- Every part (brightness, volume, large, small, media) can be added more than once.
- Drag-and-drop list for the order of the parts (arrows still work). Old "sliders" layouts are converted.

Author / About
- Version 0.7.3 Beta, author ItsNotMeBro, code: "This is Vibe Code - Written with Claude".

# Kontrol Center v7 (changes over v6)

Popup / window
- Window type is now AppletPopup (same as Plasma's own widgets): floating gap to the bar/screen edge, and KWin
  effects (rounded corners outline) treat it like the other widgets. Settings window is untouched.
- The window is fixed to the panel's size and the panel is built + filled with data when Plasma starts, so the
  first open is complete (media banner, bottom button rows). No need to toggle "classic popup" any more.

Look
- One spacing value (12 px) for panel padding and every gap; large buttons use equal-width columns.
- Session buttons (lock/logout/restart/power) are flush right.
- Panel can follow system light/dark colours.
- Transparent (see-through) and Translucent (blurred) modes, mutually exclusive, each with a 0-100 % slider.
- On colour = brightest shade of the Plasma accent, Off colour = darkest shade (both optional).
- Media banner: colour = off colour / on colour / custom (colour wheel), and optional idle banner.

Layout editor (Settings > Buttons)
- Up/down arrows and a remove (bin) button for every part; add parts back from "Add to the panel".
- Sliders and media banner: once only. Large/small button groups: as many as you like.
- Add / Remove button inside each group. Removed groups keep their buttons, so re-adding restores them.
