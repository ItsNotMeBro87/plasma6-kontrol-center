#!/bin/bash
# Toggle a background inhibitor.   usage: inhibit.sh NAME kde-inhibit-args...
name="$1"; shift
pf="$HOME/.cache/kontrol-center/$name.pid"
mkdir -p "$(dirname "$pf")"
if [ -f "$pf" ] && kill -0 "$(cat "$pf")" 2>/dev/null; then
  kill -- -"$(cat "$pf")" 2>/dev/null || kill "$(cat "$pf")" 2>/dev/null
  rm -f "$pf"
  exit 0
fi
if command -v kde-inhibit >/dev/null 2>&1; then
  setsid kde-inhibit "$@" sleep infinity >/dev/null 2>&1 &
elif [ "$name" = "caffeine" ]; then
  setsid systemd-inhibit --what=idle:sleep --who=KontrolCenter --why=Awake sleep infinity >/dev/null 2>&1 &
else
  exit 1
fi
pid=$!
sleep 0.4
if kill -0 "$pid" 2>/dev/null; then echo "$pid" > "$pf"; else rm -f "$pf"; exit 1; fi
