#!/bin/bash
# Kontrol Center - dependency check. Shows which helper programs are present on this system.
# Usage: ./check-deps.sh
req="nmcli:Wi-Fi button (NetworkManager)
bluetoothctl:Bluetooth button (bluez)
rfkill:Airplane button (rfkill)
wpctl:Volume and mic (WirePlumber)
pactl:Volume (PulseAudio tools / pipewire-pulse)
notify-send:Notifications (libnotify)
wl-copy:Copy colors to the clipboard (wl-clipboard)
gdbus:Color picker (glib2 tools)
kreadconfig6:Reads Plasma settings (Plasma 6)
kwriteconfig6:Writes Plasma settings (Plasma 6)"
opt="playerctl:Media banner
ddcutil:Brightness bars for external monitors
brightnessctl:Brightness bar for laptop screens
powerprofilesctl:Power Profile button
kscreen-doctor:Pen Display button
systemsettings:Settings shortcuts
spectacle:Capture and Record buttons
plasma-apply-colorscheme:Dark / Light button
kcolorchooser:Color picker fallback
iwgetid:Wi-Fi name fallback
warp-cli:Cloudflare button (Cloudflare WARP)"
miss=0
echo "== Required =="
while IFS=: read -r c d; do
  if command -v "$c" >/dev/null 2>&1; then printf '  ok       %-26s %s\n' "$c" "$d"
  else printf '  MISSING  %-26s %s\n' "$c" "$d"; miss=$((miss+1)); fi
done <<< "$req"
echo; echo "== Optional (only for the feature named) =="
while IFS=: read -r c d; do
  if command -v "$c" >/dev/null 2>&1; then printf '  ok       %-26s %s\n' "$c" "$d"
  else printf '  missing  %-26s %s\n' "$c" "$d"; fi
done <<< "$opt"
echo
if kreadconfig6 --version >/dev/null 2>&1; then echo "Plasma 6 tools found."; else echo "kreadconfig6 not found: Kontrol Center needs Plasma 6."; fi
[ $miss -eq 0 ] && echo "All required tools are installed." || echo "$miss required tool(s) missing - see the Dependencies section of the README."
