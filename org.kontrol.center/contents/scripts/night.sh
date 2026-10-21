#!/bin/bash
# Toggle KDE Night Light. --notify makes KWin pick the change up immediately.
f=kwinrc; g=NightColor
w() { kwriteconfig6 --notify --file $f --group $g "$@"; }
if [ "$(kreadconfig6 --file $f --group $g --key Active)" = "true" ]; then
  w --key Active false
else
  mode=$(kreadconfig6 --file $f --group $g --key Mode)
  if [ -z "$mode" ] || [ "$mode" = "Automatic" ]; then
    w --key Mode Constant
    [ -z "$(kreadconfig6 --file $f --group $g --key NightTemperature)" ] && w --key NightTemperature 4500
  fi
  w --key Active true
fi
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
