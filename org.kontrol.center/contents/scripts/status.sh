#!/bin/bash
# Prints key=value lines describing the system state. Read by main.qml.
# usage: status.sh <player-name-filter (optional)> <pen-display-output>
# Every external call has a timeout so one stuck tool can never freeze the widget.
match="${1:-}"
penout="${2:-HDMI-A-1}"
cache="$HOME/.cache/kontrol-center"
T="timeout 2"

# Wi-Fi
echo "wifi=$($T nmcli radio wifi 2>/dev/null)"
if $T nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^wifi:connected'; then
  echo "wificonn=1"
  # name (SSID) of the network we are connected to; terse nmcli escapes ':' as '\:'
  ssid=$($T nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null | awk -F: '$1=="yes"{sub(/^yes:/,""); print; exit}' | sed 's/\\:/:/g')
  [ -z "$ssid" ] && ssid=$($T iwgetid -r 2>/dev/null)
  [ -z "$ssid" ] && ssid=$($T nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$1=="wifi" && $2=="connected"{print $3; exit}')
  echo "ssid=$ssid"
else
  echo "wificonn=0"; echo "ssid="
fi

# Bluetooth: only ask bluetoothctl when a controller exists (it hangs forever otherwise)
if [ -n "$(ls /sys/class/bluetooth 2>/dev/null)" ]; then
  if $T bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo "bt=on"; else echo "bt=off"; fi
  n=$($T bluetoothctl devices Connected 2>/dev/null | grep -c '^Device')
  echo "btcount=${n:-0}"
  if [ "${n:-0}" -gt 0 ]; then echo "btconn=1"; else echo "btconn=0"; fi
else
  echo "bt=off"; echo "btconn=0"; echo "btcount=0"
fi

# Volume
v=$($T wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
echo "vol=$(echo "$v" | awk '{print $2}')"
case "$v" in *MUTED*) echo "muted=1" ;; *) echo "muted=0" ;; esac

# Microphone: present = a real (non-monitor) input exists; muted = default input is muted
if $T pactl list short sources 2>/dev/null | awk '{print $2}' | grep -qv '\.monitor$'; then
  echo "mic=1"
  case "$($T wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)" in *MUTED*) echo "micmuted=1" ;; *) echo "micmuted=0" ;; esac
else
  echo "mic=0"; echo "micmuted=0"
fi

# Pen display (same detection logic as your toggle-kamvas script)
if timeout 3 kscreen-doctor --outputs 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -A 3 "$penout" | grep -q "enabled"; then echo "pen=1"; else echo "pen=0"; fi

# Headphones = default sink's active port
sink=$($T pactl get-default-sink 2>/dev/null)
port=$($T pactl list sinks 2>/dev/null | awk -v s="$sink" '$1=="Name:"{cur=$2} cur==s && /Active Port:/{print $3; exit}')
if [ "$port" = "analog-output-headphones" ]; then echo "headphone=1"; else echo "headphone=0"; fi

# Awake
if [ -f "$cache/caffeine.pid" ] && kill -0 "$(cat "$cache/caffeine.pid")" 2>/dev/null; then echo "caffeine=1"; else echo "caffeine=0"; fi

# DND: ask Plasma itself (sees changes made from the system tray too)
inh=$($T busctl --user get-property org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Inhibited 2>/dev/null | awk '{print $2}')
if [ "$inh" = "true" ]; then echo "dnd=1"; elif [ "$inh" = "false" ]; then echo "dnd=0"; else
  u=$($T kreadconfig6 --file plasmanotifyrc --group DoNotDisturb --key Until 2>/dev/null)
  if [ -n "$u" ] && [[ "$u" > "$(date +%Y-%m-%dT%H:%M:%S)" ]]; then echo "dnd=1"; else echo "dnd=0"; fi
fi

# Accent colour: Plasma stores the (wallpaper) accent in kdeglobals
acc=$($T kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null)
[ -z "$acc" ] && acc=$($T kreadconfig6 --file kdeglobals --group Colors:Selection --key BackgroundNormal 2>/dev/null)
echo "accent=$acc"

# Night light
echo "night=$($T kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null)"

# Dark mode = window background luminance
bg=$($T kreadconfig6 --file kdeglobals --group Colors:Window --key BackgroundNormal 2>/dev/null)
IFS=, read -r r g b <<< "$bg"
if [ -n "$r" ] && [ $(( (${r:-255}*299 + ${g:-255}*587 + ${b:-255}*114) / 1000 )) -lt 128 ]; then echo "dark=1"; else echo "dark=0"; fi

# Airplane = every rfkill device soft-blocked
n=$($T rfkill -n -o SOFT list 2>/dev/null | grep -c .)
un=$($T rfkill -n -o SOFT list 2>/dev/null | grep -c '^unblocked')
if [ "$n" -gt 0 ] && [ "$un" -eq 0 ]; then echo "airplane=1"; else echo "airplane=0"; fi

# Cloudflare WARP
if $T warp-cli status 2>/dev/null | grep -q "Status update: Connected"; then echo "warp=1"; else echo "warp=0"; fi

# Power profile
echo "profile=$($T powerprofilesctl get 2>/dev/null)"

# Uptime
awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60);
      if (d>0) printf "uptime=%dd %dh %dm\n", d, h, m; else printf "uptime=%dh %dm\n", h, m}' /proc/uptime

# Player filter: empty = any player; "ytm,spotify" = only players whose name contains ytm OR spotify
player_ok() {
  [ -z "$match" ] && return 0
  local t; local IFS=','
  for t in $match; do
    t="${t#"${t%%[![:space:]]*}"}"; t="${t%"${t##*[![:space:]]}"}"
    [ -n "$t" ] && echo "$1" | grep -qiF -- "$t" && return 0
  done
  return 1
}

# Media: ANY MPRIS player (Firefox, Spotify, mpv, ytm-player...). Prefer one that is Playing, then Paused.
sel=""
for p in $($T playerctl -l 2>/dev/null); do
  if ! player_ok "$p"; then continue; fi
  st=$(timeout 1 playerctl -p "$p" status 2>/dev/null)
  if [ "$st" = "Playing" ]; then sel="$p"; break; fi
  if [ "$st" = "Paused" ] && [ -z "$sel" ]; then sel="$p"; fi
done
if [ -n "$sel" ]; then
  echo "player=$sel"
  echo "media=$(timeout 2 playerctl -p "$sel" metadata --format '{{status}}|||{{artist}}|||{{title}}|||{{album}}|||{{xesam:contentCreated}}|||{{mpris:artUrl}}|||{{position}}|||{{mpris:length}}' 2>/dev/null | head -n1)"
fi
