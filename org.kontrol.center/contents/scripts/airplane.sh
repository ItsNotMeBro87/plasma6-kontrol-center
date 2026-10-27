#!/bin/bash
# airplane.sh off WIFI BT   -> leave airplane mode and put Wi-Fi / Bluetooth back the way they were before
#                              (WIFI and BT are 1 = was on, 0 = was off). Plain "rfkill unblock all" would make
#                              Bluetooth power itself on again, which is what this script prevents.
case "$1" in
  off)
    rfkill unblock all >/dev/null 2>&1
    sleep 1.5
    if [ "$2" = 0 ]; then nmcli radio wifi off >/dev/null 2>&1; else nmcli radio wifi on >/dev/null 2>&1; fi
    if [ "$3" = 0 ]; then
      for _ in 1 2 3 4 5 6 7 8; do
        s=$(timeout 3 bluetoothctl show 2>/dev/null)
        if echo "$s" | grep -q 'Powered: yes'; then timeout 3 bluetoothctl power off >/dev/null 2>&1; break; fi
        echo "$s" | grep -q 'Powered: no' && break
        sleep 1
      done
    else
      timeout 3 bluetoothctl power on >/dev/null 2>&1
    fi
    ;;
esac
exit 0
