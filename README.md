<div align="center">

<img width="64" height="64" alt="kc-gear" src="https://github.com/user-attachments/assets/0cb46fcd-2633-4d42-9686-adb37b6849da" />

# Kontrol Center

A fully configurable control center widget for the KDE Plasma 6 panel. You decide which parts exist, how they look, and in which order.

</div>

<img width="1920" height="1080" alt="Kontrol Center - KDE Plasma Control Center" src="https://github.com/user-attachments/assets/274d1903-365a-4a8d-9fef-a672cbeb7c07" />

## Control Center for KDE Plasma 6

## Features

- **Native Plasma widget.** Written in QML with small shell scripts, so it should stay light on memory.
- **Brightness.** Control screen brightness for external monitors and laptops.
- **Volume slider.** Control the volume via click or scrollwheel.
- **Prebuilt Smart Toggles.** Wi-Fi shows *Off / On / the network name*. Bluetooth shows *Off / On - Not connected / Connected (N devices)*. Also Power Profile, Do Not Disturb, Caffeine (keep awake), Night Light, Dark / Light mode, Airplane mode, Cloudflare WARP, Mic, Color Picker, Screenshot and Screen Recording (Spectacle). Airplane mode remembers whether Wi-Fi and Bluetooth were on and puts them back that way; after login, Wi-Fi, Bluetooth and Airplane mode return to how you last left them.
- **Custom buttons.** Add *Custom* buttons with an ON command and an OFF command or your own toggle script.
- **Media banner.** Works with any MPRIS player (Spotify, YouTube Music, Firefox, VLC, etc). Its color can follow the album cover's accent, in a dark or a light shade.
- **Long text scrolls.** Text that does not fit (a long network name, "On - Not connected", a song or album title ...) is cut with "..." and scrolls from right to left while the mouse is over it.
- **Custom layout.** Drag and drop the parts (brightness, volume, large buttons, small buttons, media banner) into any order and can be reordered by drag and drop. If everything does not fit on the screen, scroll arrows appear.
- **Layout profiles.** Save the layout only, or the layout with the current colors, under a name and load it again later. Profiles are plain files on your PC, with no limit on how many.
- **Custom shapes.** Separate corner radius for the panel, slider bars, large buttons, small buttons and the media banner (from boxy to pill-shaped), a panel width you can change, and a **Scale** that enlarges or shrinks the whole widget.
- **Custom colors.** Choose colors yourself (36 quick swatches: recent, dark and light), or just follow your Plasma accent. Optional border and shadow (with adjustable shadow blur) for the panel, buttons and banner, and text that stays readable on a see-through panel.
- **Custom icons.** It comes packed with pre-built icons, but if you're not satisfied, you can customize and change them to your own liking.
- **Languages.** The popup can be shown in English, Bahasa Indonesia, Deutsch, Español, Français, 日本語, Português, 한국어, Русский, 中文 (简体) or العربية (right-to-left). The translations were written by hand and by Claude, so wording may be off in places.

## Requirements

- **KDE Plasma 6** (6.0 or newer). Plasma 5 is not supported.
- Wayland or X11.
- A few common helper programs (see [Dependencies](#dependencies)). Most are already installed on a normal
  Plasma desktop. Each button only needs the tools for its own feature.

Distros that ship Plasma 6: Arch Linux and derivatives (CachyOS, EndeavourOS, Manjaro, ...), Fedora KDE 42+
and Nobara, openSUSE Tumbleweed and Leap 16, Debian 13, KDE neon, Kubuntu 25.04 and newer.
**Not supported:** Kubuntu 24.04 LTS (Plasma 5.27), Debian 12, openSUSE Leap 15.6.

## Installation

### A. Via native Plasma desktop KDE Store **(RECOMMENDED)**

1. Right-click on the Plasma bar, and choose **Add or Manage Widgets...**
2. Click **Download New Plasma Widget...** from **Get New...** option.
3. Search for "Kontrol Center" and install it.
4. Restart Plasma or log out and log back in to your session.
5. Right-click the panel, **Add or Manage Widgets...**, and add **Kontrol Center**.

### B. Via the `.plasmoid` file

1. Download `kontrol-center-0.7.7-beta.plasmoid` from the [Releases](https://github.com/ItsNotMeBro87/plasma6-kontrol-center/releases) page.
2. Install it, either from a terminal:

   ```bash
   kpackagetool6 -t Plasma/Applet -i kontrol-center-0.7.7-beta.plasmoid
   ```

   or from the desktop: right-click the panel or desktop, **Add or Manage Widgets...**, **Get New...**, **Install Widget From Local File...**, and pick the file.
3. Restart Plasma so it finds the widget: `kquitapp6 plasmashell; kstart plasmashell` (or log out and in again).
4. Right-click the panel, **Add or Manage Widgets...**, and add **Kontrol Center**.

To update later, run the same command with `-u` instead of `-i`, then restart Plasma.

### C. Install from the source

```bash
git clone https://github.com/ItsNotMeBro87/plasma6-kontrol-center.git
cd plasma6-kontrol-center
./install.sh
```

`install.sh` also downloads the real [Tabler](https://tabler.io/icons) button icons (it needs `curl`). If that fails, the bundled icons are used, so it is optional.

### Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r org.kontrol.center
```

Your profiles stay in `~/.local/share/kontrol-center/profiles`. Delete that folder if you do not want them.

## Dependencies

Run `./check-deps.sh` (it is in this repository) to see what is missing on your system.

### What each feature needs

| Feature | Program | Typical package |
|---|---|---|
| Wi-Fi button and page | `nmcli` | NetworkManager |
| Bluetooth button and page | `bluetoothctl` | bluez (bluez-utils on Arch) |
| Bluetooth pairing requests in the widget | `python3` with `gi` (PyGObject) | python-gobject / python3-gi |
| Airplane button | `rfkill` | util-linux or rfkill |
| Volume and mic | `wpctl`, `pactl` | WirePlumber, PipeWire-Pulse / PulseAudio tools |
| Sound page | `pactl` 16 or newer (needs `--format=json`) | PipeWire-Pulse / PulseAudio tools |
| Color picker, clipboard | `gdbus`, `wl-copy`, `notify-send` | glib2 tools, wl-clipboard, libnotify |
| Brightness (external monitor) | `ddcutil` | ddcutil |
| Brightness (laptop) | `brightnessctl` | brightnessctl |
| Media banner | `playerctl` | playerctl |
| Power Profile button | `powerprofilesctl` | power-profiles-daemon |
| Pen Display button | `kscreen-doctor` | part of KScreen / libkscreen |
| Capture and Record | `spectacle` | Spectacle |
| Settings shortcuts | `systemsettings` | System Settings |
| Dark / Light, Night Light | `kreadconfig6`, `kwriteconfig6`, `plasma-apply-colorscheme` | part of Plasma 6 |
| Optional | `kcolorchooser`, `iwgetid` | picker and Wi-Fi name fallbacks |
| Optional | `warp-cli` | Cloudflare WARP (from Cloudflare's own repository) |

### Install the extras

The KDE tools in the table come with a normal Plasma install. These commands add the other helpers.
If a package name is not found on your release, look up the right one (see the end of this section).

**Arch Linux, CachyOS, EndeavourOS, Manjaro**

```bash
sudo pacman -S --needed networkmanager bluez bluez-utils wireplumber pipewire-pulse libpulse \
  playerctl wl-clipboard libnotify glib2 util-linux power-profiles-daemon ddcutil brightnessctl \
  wireless_tools python-gobject kcolorchooser spectacle systemsettings kscreen kde-cli-tools
```

**Fedora KDE, Nobara**

```bash
sudo dnf install NetworkManager bluez wireplumber pipewire-pulseaudio pulseaudio-utils playerctl \
  wl-clipboard libnotify glib2 util-linux power-profiles-daemon ddcutil brightnessctl wireless-tools \
  python3-gobject kcolorchooser spectacle plasma-systemsettings kscreen kde-cli-tools
```

Newer Fedora uses `tuned-ppd` for power profiles by default, which can conflict with
`power-profiles-daemon`. If dnf complains, leave that package out.

**Kubuntu, KDE neon, Debian 13**

```bash
sudo apt install network-manager bluez wireplumber pipewire-pulse pulseaudio-utils playerctl \
  wl-clipboard libnotify-bin libglib2.0-bin rfkill power-profiles-daemon ddcutil brightnessctl \
  wireless-tools python3-gi kcolorchooser spectacle systemsettings kscreen libkscreen-bin \
  kde-cli-tools libkf6config-bin
```

**openSUSE Tumbleweed**

```bash
sudo zypper install NetworkManager bluez wireplumber pipewire-pulseaudio pulseaudio-utils playerctl \
  wl-clipboard libnotify-tools glib2-tools rfkill power-profiles-daemon ddcutil brightnessctl \
  wireless-tools python3-gobject kcolorchooser spectacle systemsettings6 libkscreen6-plugin kde-cli-tools6
```

**After installing**

- Make sure the services run: `sudo systemctl enable --now bluetooth NetworkManager`
- **Brightness for external monitors (DDC/CI)** needs the `i2c-dev` kernel module and access to it:

  ```bash
  sudo modprobe i2c-dev
  echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
  sudo usermod -aG i2c $USER      # then log out and in again
  ```

  Laptop panels use `brightnessctl` and do not need this.

**Find the package for a missing command**

| Distro | Command |
|---|---|
| Arch family | `pacman -F kscreen-doctor` |
| Fedora / Nobara | `dnf provides '*/kscreen-doctor'` |
| Debian / Kubuntu / neon | `apt-file search bin/kscreen-doctor` |
| openSUSE | `zypper wp kscreen-doctor` |

## Customization

Right-click the widget and choose **Configure Kontrol Center...**.

**General**

- **Widget icon:** the icon on your panel. Pick a theme icon or an SVG file. Keep **Keep the colors of an SVG
  icon** ticked for colorful icons, or untick it to tint a one-color SVG like your panel text.
- **Header:** show or hide the date, pick one of 10 date formats, show or hide the uptime.
- **Language:** the language of the popup (default English; 11 languages). The settings windows stay in English.

**Appearance**

- **Panel:** corner radius, **width**, **scale** (enlarges or shrinks the whole widget, not only its width), colors, **transparency** (0 = solid), text and icon readability on a
  see-through panel, **blur**, and an optional **border** and **shadow** with their own colors (a border width and a shadow blur). Blur needs the Blur desktop effect (System Settings > Window Management > Desktop Effects). KWin has no
  per-widget blur strength, so there is an optional checkbox that also sets KWin's global blur strength (this
  affects all blurred windows, and is off by default).
- **Button Corner Radius:** separate radius for slider bars, large buttons, small buttons and the media banner.
  The Wi-Fi, Bluetooth, Picker and Sound pages use the radius of the button that opened them.
- **Button and Slider Colors:** On color, Off color, and optional border and shadow colors. Every color field has
  swatches (12 recent, 12 dark, 12 light), a color dialog and a hex box. You can follow the Plasma accent color or
  the system light / dark mode. With *follow system* on, only the panel color is locked.
- **Media banner:** same as the off-state buttons, same as the lit buttons, **album cover accent - dark**, **album cover accent - light**, or a custom color; plus optional border and shadow.

**Layout and Buttons**

- **Order of the parts:** drag the parts (brightness, volume, large buttons, small buttons, media banner) to
  reorder them, or use the arrows. Add parts again with **Add**; each kind can exist several times. Remove
  one with the bin icon.
- **Buttons:** click a button to edit it (name, icon, command). Drag buttons to reorder them inside their group. A button can appear several times, for example once large and once small.
- **Custom buttons:** type the command to run when the button turns ON and when it turns OFF.
- **Pen Display and Headset:** these are not in the default layout, but you can add them from the button
  list. Set **Toggle script** to a script of your own; for Pen Display also set the screen name (for example
  `HDMI-A-1`, as shown by `kscreen-doctor -o`). With an empty script they do nothing.
- **Profiles:** save a layout under a name, either **layout only** or **layout with current colors**, and load
  it again later. Files live in `~/.local/share/kontrol-center/profiles`.
- **Behavior:** volume and brightness wheel step, media player filter (several players separated by commas,
  for example `ytm, spotify`; run `playerctl -l` to see the exact player names), and the Plasma color schemes
  used by the Dark / Light button. Type the **name** of a color scheme for each mode (defaults: `BreezeDark`,
  `BreezeLight`). Run `plasma-apply-colorscheme --list-schemes` to see the exact names of the schemes installed on
  your PC, for example `BreezeClassic`, `Oxygen`, or third-party ones such as `Catppuccin-Mocha-Mauve`. A color
  scheme only changes colors, not the application style, icons or Plasma theme. Kvantum is an application style,
  not a color scheme, so it cannot be typed there, but many Kvantum themes ship matching KDE color schemes
  (for example `KvantumDark`) that you can use.

> **Security note.** Custom buttons run the commands you type, as your user. Only use commands you understand
> and trust. Profiles saved by other people can contain such commands, so read them before loading them.


## Demo and Screenshots


https://github.com/user-attachments/assets/0e99da14-9b41-4eb9-ad5a-564da76f599d


<img width="431" height="618" alt="kontrol center SS" src="https://github.com/user-attachments/assets/b1f5c63e-af09-4095-8b2c-cd6e1093b991" />
<img width="1511" height="1312" alt="config colors" src="https://github.com/user-attachments/assets/cefe39c7-fa49-4114-9b5c-6f21e499bb9d" /> <img width="1603" height="1401" alt="config buttons" src="https://github.com/user-attachments/assets/8b1c14c9-88dd-47f9-a8dc-2d6b5cf29a93" />


## Troubleshooting

- **Something does not work:** run `./check-deps.sh` first.
- **No brightness bar:** run
  `bash ~/.local/share/plasma/plasmoids/org.kontrol.center/contents/scripts/brightness.sh debug`
  and read what the system reports. For external monitors check the DDC/CI steps above and that DDC/CI is
  enabled in the monitor's own menu.
- **Color picker does nothing:** run
  `bash ~/.local/share/plasma/plasmoids/org.kontrol.center/contents/scripts/picker.sh pick`
  in a terminal and include its output in an issue.
- **Widget does not show up after installing:** restart Plasma (`kquitapp6 plasmashell; kstart plasmashell`).
- **Wi-Fi page is empty:** run `bash ~/.local/share/plasma/plasmoids/org.kontrol.center/contents/scripts/wifi.sh list`.
  Each line starting with `W|` is a network. No output means `nmcli` found no Wi-Fi device.
- **Bluetooth page is empty or pairing requests do not show:** run the same with `bt.sh list`. Pairing requests
  are shown in the widget only while the Bluetooth page is open and `python3` with `gi` is installed; otherwise
  KDE's own pairing notification is used as usual.
- **Sound page is empty:** run `pactl --format=json list sinks`. If that prints an error, your `pactl` is too old.
- **Blur does nothing:** see the note under *Appearance*. A per-widget blur strength is not something KWin offers.

## Limitations

- **This began as a personal project** made for one person's desktop and then shared. Several buttons may
  not work on your system, depending on your hardware, distro and which tools are installed. The Pen Display
  and Headset buttons only work after you set your own scripts.
- **It is vibe-coded.** The code was written with Claude (an AI assistant), guided and tested by one person
  on one setup (CachyOS with Plasma 6). Expect rough edges, and read the code before you trust it with
  anything important.
- **It may not be updated.** The author may be busy, so fixes and new features are not promised.
- **Beta software.** Settings and file formats may change between versions.
- **The Wi-Fi, Bluetooth and Sound pages are new in 0.7.7** and have had the least testing. Bluetooth pairing
  in particular depends on your BlueZ version and on KDE's own Bluetooth agent. If something breaks, please
  open an issue with the output of the matching script (see Troubleshooting).
- A Wi-Fi password is passed to `nmcli` on its command line for a moment (the standard way for scripts), so
  another program running as the same user could see it during that moment.
- Not tested on every distro, GPU, monitor or Plasma version. Plasma 5 is not supported.

## Issues

Even if the widget is not updated often, **please do open an issue** if you find a problem or have an idea
for a feature. First search the existing issues to see if someone already reported the same thing; if so,
add your details there instead of opening a new one.

A good bug report includes your distro and version, your Plasma version (`plasmashell --version`), X11 or
Wayland, the Kontrol Center version, what you expected, what happened, and the output of
`./check-deps.sh`. Pull requests are welcome too, since the project is open source.

## Credits and license

- Written with Claude by ItsNotMeBro87. Version 0.7.7 Beta.
- Button icons: [Tabler Icons](https://tabler.io/icons) (MIT) and Lucide (ISC), plus a few hand-drawn icons used as fallbacks. See [NOTICE.md](NOTICE.md).
- Licensed under the **GNU General Public License v3.0 or later**. See [LICENSE](LICENSE). In short:
  you can use, study, share and modify it, and if you share a modified version it must stay open source
  under the same license.

