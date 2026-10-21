#!/bin/bash
# blur.sh N  (1-100) -> sets KWin's blur strength (1-15). This is a SYSTEM-WIDE setting
# (System Settings > Desktop Effects > Blur): KWin has no per-widget blur strength.
n=${1:-0}
[ "$n" -gt 0 ] 2>/dev/null || exit 0
s=$(( 1 + n * 14 / 100 ))
kwriteconfig6 --file kwinrc --group Effect-blurplugin --key BlurStrength "$s"
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 \
  || qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
exit 0
