#!/bin/bash
# restore.sh WIFI BT AIRPLANE -> once per login session, put Wi-Fi, Bluetooth and airplane mode back to the state
# they had when the PC was last used (1 = on, 0 = off). Runs when the widget first loads.
marker="${XDG_RUNTIME_DIR:-/tmp}/kontrol-center-restored"
[ -e "$marker" ] && exit 0
: > "$marker"
wifi="${1:-1}"; bt="${2:-1}"; air="${3:-0}"
# wait (up to ~20 s) until NetworkManager and the Bluetooth adapter are there
for _ in $(seq 1 20); do
  nmcli general status >/dev/null 2>&1 && break
  sleep 1
done
if [ "$air" = 1 ]; then
  rfkill block all >/dev/null 2>&1
  exit 0
fi
if [ "$wifi" = 0 ]; then nmcli radio wifi off >/dev/null 2>&1; fi
for _ in $(seq 1 20); do
  [ -n "$(ls /sys/class/bluetooth 2>/dev/null)" ] && timeout 3 bluetoothctl show >/dev/null 2>&1 && break
  sleep 1
done
if [ "$bt" = 0 ]; then timeout 3 bluetoothctl power off >/dev/null 2>&1; fi
exit 0
