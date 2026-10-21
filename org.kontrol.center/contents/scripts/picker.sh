#!/bin/bash
# picker.sh pick [id]  -> pick a colour from the screen; prints #RRGGBB (nothing if you cancel)
# picker.sh copy HEX   -> copy HEX to the clipboard
copy_hex() {
  if command -v wl-copy >/dev/null 2>&1; then printf '%s' "$1" | wl-copy >/dev/null 2>&1
  else dbus-send --session --dest=org.kde.klipper /klipper org.kde.klipper.klipper.setClipboardContents string:"$1" >/dev/null 2>&1; fi
}
finish() {   # $1 = #RRGGBB
  copy_hex "$1"
  notify-send -u low -i color-picker "Color picked" "$1 (copied to clipboard)" >/dev/null 2>&1
  echo "$1"
  exit 0
}

if [ "$1" = "copy" ]; then
  copy_hex "$2"
  notify-send -u low -i color-picker "Color copied" "$2" >/dev/null 2>&1
  exit 0
fi

# ---- 1) KWin's own colour picker: ONE blocking D-Bus call that returns the colour -------------
# (the old version used the desktop portal, which answers with a signal addressed to the caller. A
#  command-line tool that exits after sending the request never receives it, so nothing was picked
#  and the widget kept waiting - which is why the history stayed empty and a second try did nothing.)
err=$(mktemp)
out=$(gdbus call --session --timeout 120 --dest org.kde.KWin --object-path /ColorPicker \
      --method org.kde.kwin.ColorPicker.pick 2>"$err")
rc=$?
errtxt=$(cat "$err"); rm -f "$err"
if [ $rc -eq 0 ]; then
  # answer is either one ARGB number "((4286019584,),)" or 16-bit parts "((1, 65535, R, G, B, 0),)"
  hex=$(printf '%s' "$out" | sed -E 's/(u|)int[0-9]+//g' | grep -oE '[0-9]+' | awk '
      {v[NR]=$1}
      END{
        if (NR==1)      printf "#%02X%02X%02X", int(v[1]/65536)%256, int(v[1]/256)%256, v[1]%256
        else if (NR>=5) printf "#%02X%02X%02X", int(v[3]/257+0.5), int(v[4]/257+0.5), int(v[5]/257+0.5)
      }')
  [ -n "$hex" ] && finish "$hex"
  exit 0
fi
case "$errtxt" in *ancel*) exit 0 ;; esac      # you pressed Esc

# ---- 2) desktop portal, with a connection that stays open until the answer arrives --------------
if command -v python3 >/dev/null 2>&1; then
  hex=$(python3 - <<'PY' 2>/dev/null
import sys
try:
    from gi.repository import Gio, GLib
except Exception:
    sys.exit(3)
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
loop = GLib.MainLoop()
res = {}
def on_resp(conn, sender, path, iface, sig, params, ud):
    code, results = params.unpack()
    if code == 0 and "color" in results:
        res["c"] = results["color"]
    loop.quit()
bus.signal_subscribe(None, "org.freedesktop.portal.Request", "Response", None, None, Gio.DBusSignalFlags.NONE, on_resp, None)
bus.call_sync("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
              "org.freedesktop.portal.Screenshot", "PickColor",
              GLib.Variant("(sa{sv})", ("", {})), None, Gio.DBusCallFlags.NONE, -1, None)
GLib.timeout_add_seconds(120, loop.quit)
loop.run()
if "c" in res:
    r, g, b = res["c"]
    print("#%02X%02X%02X" % (round(r * 255), round(g * 255), round(b * 255)))
else:
    sys.exit(4)
PY
)
  prc=$?
  [ -n "$hex" ] && finish "$hex"
  [ $prc -eq 4 ] && exit 0                    # portal worked, you cancelled
fi

# ---- 3) last resort: KColorChooser's screen picker ----------------------------------------------
if command -v kcolorchooser >/dev/null 2>&1; then
  hex=$(kcolorchooser --print 2>/dev/null | grep -oE '#[0-9A-Fa-f]{6}' | head -n1 | tr 'a-f' 'A-F')
  [ -n "$hex" ] && finish "$hex"
  exit 0
fi
notify-send -u low "Color picker" "No color picker available (KWin picker, desktop portal and KColorChooser all failed)" >/dev/null 2>&1
exit 1
