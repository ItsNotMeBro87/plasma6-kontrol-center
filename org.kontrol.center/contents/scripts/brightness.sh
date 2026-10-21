#!/bin/bash
# list            -> one line per display:  name|label|current|max
# set NAME VALUE  -> set raw brightness
# debug           -> show what the system reports (use this if no bar appears)
# 1) Plasma's ScreenBrightness service (same one KDE's own brightness control uses)
# 2) ddcutil directly (cached, DDC/CI monitors)  3) brightnessctl (laptop panel)
svc=org.kde.ScreenBrightness
bus() { timeout 3 busctl --user "$@" 2>/dev/null; }
cache="$HOME/.cache/kontrol-center"; ddc="$cache/ddc.list"

plasma_names() {
  bus get-property $svc /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames | grep -o '"[^"]*"' | tr -d '"'
}

ddc_list() {
  command -v ddcutil >/dev/null 2>&1 || return
  mkdir -p "$cache"
  if [ -f "$ddc" ] && [ $(( $(date +%s) - $(stat -c %Y "$ddc") )) -lt 90 ]; then cat "$ddc"; return; fi
  : > "$ddc.tmp"
  det=$(timeout 15 ddcutil detect --brief 2>/dev/null)
  for n in $(echo "$det" | awk '/^Display/{print $2}'); do
    model=$(echo "$det" | awk -v n="$n" '$1=="Display"{on=($2==n)} on && /Monitor:/{split($2,a,":"); print a[2]; exit}')
    vcp=$(timeout 10 ddcutil --display "$n" getvcp 10 --brief 2>/dev/null)
    cur=$(echo "$vcp" | awk '{print $4}'); max=$(echo "$vcp" | awk '{print $5}')
    [ -n "$cur" ] && echo "ddc:$n|${model:-Monitor $n}|$cur|${max:-100}" >> "$ddc.tmp"
  done
  mv "$ddc.tmp" "$ddc"; cat "$ddc"
}

case "$1" in
list)
  names=$(plasma_names)
  if [ -n "$names" ]; then
    for n in $names; do
      p=/org/kde/ScreenBrightness/$n
      label=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display Label | sed 's/^s "\(.*\)"$/\1/')
      cur=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display Brightness | awk '{print $2}')
      max=$(bus get-property $svc "$p" org.kde.ScreenBrightness.Display MaxBrightness | awk '{print $2}')
      echo "$n|${label:-$n}|${cur:-0}|${max:-100}"
    done
  else
    out=$(ddc_list)
    if [ -n "$out" ]; then echo "$out"
    elif command -v brightnessctl >/dev/null 2>&1; then
      brightnessctl -m 2>/dev/null | head -n1 | awk -F, '{print "brightnessctl|Internal display|" $3 "|" $5}'
    fi
  fi ;;
set)
  case "$2" in
    brightnessctl) brightnessctl set "$3" >/dev/null 2>&1 ;;
    ddc:*) n="${2#ddc:}"; timeout 10 ddcutil --display "$n" setvcp 10 "$3" >/dev/null 2>&1
           [ -f "$ddc" ] && sed -i "s#^ddc:$n|\(.*\)|[0-9]*|\([0-9]*\)\$#ddc:$n|\1|$3|\2#" "$ddc" ;;
    *) bus call $svc "/org/kde/ScreenBrightness/$2" org.kde.ScreenBrightness.Display SetBrightness iu "$3" 1 >/dev/null ;;
  esac ;;
debug)
  echo "== Plasma ScreenBrightness service =="
  timeout 3 busctl --user get-property $svc /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames
  echo "== list output =="; "$0" list
  echo "== ddcutil =="; command -v ddcutil >/dev/null && timeout 15 ddcutil detect --brief ;;
esac
