#!/bin/bash
# Bluetooth helper for the Kontrol Center Bluetooth page.
#   bt.sh list      -> P|missing   or   P|powered(on/off)|discoverable(on/off)
#                      B|mac|connected|paired|trusted|icon|rssi|battery|hex(name)   (one per device)
#                      Q|kind|hex(name)|code     (a pairing request waiting for an answer, from bt-agent.py)
#   bt.sh power on|off          bt.sh discoverable on|off
#   bt.sh connect MAC           (pairs first if the device is not paired yet)
#   bt.sh disconnect MAC        bt.sh remove MAC        bt.sh trust MAC on|off
#   bt.sh scan                  (looks for devices for ~12 s)
#   bt.sh answer yes|no [text]  (answers a pairing request)
#   bt.sh agent-start | agent-stop
dir="$(cd "$(dirname "$0")" && pwd)"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/kontrol-center"
mkdir -p "$cache"
T="timeout 3"
tohex() { printf '%s' "$1" | od -An -tx1 | tr -d ' \n'; }
okmac() { [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; }

case "$1" in
  list)
    touch "$cache/bt-alive"
    if [ -z "$(ls /sys/class/bluetooth 2>/dev/null)" ]; then echo "P|missing"; exit 0; fi
    show=$($T bluetoothctl show 2>/dev/null)
    pw=off; echo "$show" | grep -q 'Powered: yes' && pw=on
    di=off; echo "$show" | grep -q 'Discoverable: yes' && di=on
    echo "P|$pw|$di"
    [ -f "$cache/bt-request" ] && echo "Q|$(cat "$cache/bt-request")"
    [ "$pw" = on ] || exit 0
    $T bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
      okmac "$mac" || continue
      info=$($T bluetoothctl info "$mac" 2>/dev/null)
      conn=0;    echo "$info" | grep -q 'Connected: yes' && conn=1
      paired=0;  echo "$info" | grep -q 'Paired: yes' && paired=1
      trusted=0; echo "$info" | grep -q 'Trusted: yes' && trusted=1
      icon=$(echo "$info" | awk -F': ' '/^[[:space:]]*Icon:/{print $2; exit}')
      alias=$(echo "$info" | awk -F': ' '/^[[:space:]]*Alias:/{print $2; exit}')
      rssi=$(echo "$info" | awk '/RSSI:/{gsub(/[()]/,"",$NF); print $NF; exit}')
      batt=$(echo "$info" | awk '/Battery Percentage:/{gsub(/[()]/,"",$NF); print $NF; exit}')
      [ -z "$alias" ] && alias="$name"
      # devices that only advertise their address (no real name) would flood the list
      if [ $conn -eq 0 ] && [ $paired -eq 0 ] && [ "$(echo "$alias" | tr '-' ':')" = "$mac" ]; then continue; fi
      echo "B|$mac|$conn|$paired|$trusted|${icon}|${rssi}|${batt}|$(tohex "$alias")"
    done
    ;;
  power)
    if [ "$2" = on ]; then rfkill unblock bluetooth >/dev/null 2>&1; $T bluetoothctl power on >/dev/null 2>&1
    else $T bluetoothctl power off >/dev/null 2>&1; fi
    ;;
  discoverable)
    if [ "$2" = on ]; then $T bluetoothctl pairable on >/dev/null 2>&1; $T bluetoothctl discoverable on >/dev/null 2>&1
    else $T bluetoothctl discoverable off >/dev/null 2>&1; fi
    ;;
  connect)
    okmac "$2" || exit 1
    if ! timeout 3 bluetoothctl info "$2" 2>/dev/null | grep -q 'Paired: yes'; then
      timeout 60 bluetoothctl pair "$2" >/dev/null 2>&1 || { echo "fail|pair"; exit 0; }
      timeout 5 bluetoothctl trust "$2" >/dev/null 2>&1
    fi
    if timeout 25 bluetoothctl connect "$2" >/dev/null 2>&1; then echo ok; else echo "fail|connect"; fi
    ;;
  disconnect) okmac "$2" && timeout 10 bluetoothctl disconnect "$2" >/dev/null 2>&1 ;;
  remove)     okmac "$2" && timeout 10 bluetoothctl remove "$2" >/dev/null 2>&1 ;;
  trust)
    okmac "$2" || exit 1
    if [ "$3" = on ]; then timeout 5 bluetoothctl trust "$2" >/dev/null 2>&1
    else timeout 5 bluetoothctl untrust "$2" >/dev/null 2>&1; fi
    ;;
  scan-wait)
    timeout 12 bluetoothctl --timeout 7 scan on >/dev/null 2>&1
    ;;
  scan)
    pgrep -f 'bluetoothctl --timeout 12 scan on' >/dev/null 2>&1 && exit 0
    setsid -f timeout 16 bluetoothctl --timeout 12 scan on >/dev/null 2>&1
    ;;
  answer)
    txt=$(printf '%s' "$3" | tr -cd 'A-Za-z0-9')
    printf '%s|%s\n' "$2" "$txt" > "$cache/bt-answer"
    ;;
  agent-start)
    command -v python3 >/dev/null 2>&1 || exit 0
    pgrep -f 'bt-agent\.py' >/dev/null 2>&1 && { touch "$cache/bt-alive"; exit 0; }
    touch "$cache/bt-alive"
    setsid -f python3 "$dir/bt-agent.py" >/dev/null 2>&1
    ;;
  agent-stop)
    pkill -f 'bt-agent\.py' >/dev/null 2>&1
    rm -f "$cache/bt-request" "$cache/bt-answer"
    ;;
esac
exit 0
