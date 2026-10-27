#!/bin/bash
# Wi-Fi helper for the Kontrol Center Wi-Fi page.
#   wifi.sh list                    -> W|active|signal|secure|freqMHz|enterprise|hex(ssid)   (visible networks)
#                                      S|hex(ssid)|hex(profile)                               (saved networks)
#                                      C|ip|interface                                         (current connection)
#   wifi.sh rescan
#   wifi.sh connect HEXSSID [HEXPASS]   -> "ok" or "fail|reason"   (names and passwords travel hex-encoded, so
#                                           no quote or special character can break the command line)
#   wifi.sh disconnect
#   wifi.sh forget HEXSSID
T="timeout"
unhex() { printf '%b' "$(printf '%s' "$1" | sed 's/../\\x&/g')"; }
tohex() { printf '%s' "$1" | od -An -tx1 | tr -d ' \n'; }
iface() { nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'; }

# name of the saved profile whose SSID is $1 (empty if none)
saved_name() {
  local want="$1" l type name ssid
  while IFS= read -r l; do
    type=${l##*:}; name=${l%:*}
    [ "$type" = "802-11-wireless" ] || continue
    ssid=$($T 2 nmcli --escape no -g 802-11-wireless.ssid connection show id "$name" 2>/dev/null)
    [ -z "$ssid" ] && ssid="$name"
    if [ "$ssid" = "$want" ]; then printf '%s' "$name"; return 0; fi
  done < <($T 4 nmcli -t --escape no -f NAME,TYPE connection show 2>/dev/null)
  return 1
}

case "$1" in
  list)
    ifc=$(iface)
    # SSID is the last field, so it may contain ':' (escaping is switched off)
    $T 5 nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list --rescan no 2>/dev/null | while IFS= read -r line; do
      inuse=${line%%:*}; rest=${line#*:}
      sig=${rest%%:*};   rest=${rest#*:}
      sec=${rest%%:*};   rest=${rest#*:}
      freq=${rest%%:*};  ssid=${rest#*:}
      [ -z "$ssid" ] && continue
      secure=0; { [ -n "$sec" ] && [ "$sec" != "--" ]; } && secure=1
      ent=0; case "$sec" in *802.1X*) ent=1 ;; esac
      act=0; [ "$inuse" = "*" ] && act=1
      echo "W|$act|${sig:-0}|$secure|${freq%% *}|$ent|$(tohex "$ssid")"
    done
    $T 5 nmcli -t --escape no -f NAME,TYPE connection show 2>/dev/null | while IFS= read -r l; do
      type=${l##*:}; name=${l%:*}
      [ "$type" = "802-11-wireless" ] || continue
      ssid=$($T 2 nmcli --escape no -g 802-11-wireless.ssid connection show id "$name" 2>/dev/null)
      [ -z "$ssid" ] && ssid="$name"
      echo "S|$(tohex "$ssid")|$(tohex "$name")"
    done
    if [ -n "$ifc" ]; then
      ip=$($T 2 nmcli --escape no -g IP4.ADDRESS device show "$ifc" 2>/dev/null | head -n1 | sed 's#/.*##')
      echo "C|$ip|$ifc"
    fi
    ;;
  rescan)
    nmcli device wifi rescan >/dev/null 2>&1
    ;;
  connect)
    ssid=$(unhex "$2"); pw=""; [ -n "$3" ] && pw=$(unhex "$3")
    ifc=$(iface)
    name=$(saved_name "$ssid")
    if [ -n "$name" ] && [ -z "$pw" ]; then
      out=$(nmcli -w 25 connection up id "$name" 2>&1); rc=$?
    elif [ -n "$name" ]; then
      nmcli connection modify id "$name" wifi-sec.psk "$pw" >/dev/null 2>&1
      out=$(nmcli -w 25 connection up id "$name" 2>&1); rc=$?
    elif [ -n "$pw" ]; then
      out=$(nmcli -w 25 device wifi connect "$ssid" password "$pw" ${ifc:+ifname "$ifc"} 2>&1); rc=$?
    else
      out=$(nmcli -w 25 device wifi connect "$ssid" ${ifc:+ifname "$ifc"} 2>&1); rc=$?
    fi
    if [ $rc -eq 0 ]; then echo "ok"; else
      # a brand new network that failed (usually a wrong password) must not stay behind as a saved network
      [ -z "$name" ] && nmcli connection delete id "$ssid" >/dev/null 2>&1
      echo "fail|$(printf '%s' "$out" | tail -n1)"
    fi
    ;;
  disconnect)
    ifc=$(iface); [ -n "$ifc" ] && nmcli device disconnect "$ifc" >/dev/null 2>&1
    ;;
  forget)
    ssid=$(unhex "$2"); name=$(saved_name "$ssid")
    [ -n "$name" ] && nmcli connection delete id "$name" >/dev/null 2>&1
    ;;
esac
exit 0
