#!/bin/bash
# Do Not Disturb toggle, based on Plasma's REAL state (so the system-tray toggle and this stay in sync).
cache="$HOME/.cache/kontrol-center"; pf="$cache/dnd.pid"; dir="$(cd "$(dirname "$0")" && pwd)"
inhibited() {
  v=$(timeout 2 busctl --user get-property org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Inhibited 2>/dev/null | awk '{print $2}')
  [ "$v" = "true" ]
}
clear_until() { kwriteconfig6 --notify --file plasmanotifyrc --group DoNotDisturb --key Until --delete; }
if inhibited; then
  # turn OFF: stop our own inhibitor and clear Plasma's "do not disturb until" time
  if [ -f "$pf" ]; then kill -- -"$(cat "$pf")" 2>/dev/null; rm -f "$pf"; fi
  clear_until
else
  # turn ON the same way the tray does (DND until a far-off date), then verify
  kwriteconfig6 --notify --file plasmanotifyrc --group DoNotDisturb --key Until "$(date -d '+10 years' +%Y-%m-%dT%H:%M:%S)"
  sleep 0.6
  if ! inhibited; then
    clear_until
    bash "$dir/inhibit.sh" dnd --notifications
  fi
fi
