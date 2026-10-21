#!/bin/bash
# Layout profiles, stored as plain files in ~/.local/share/kontrol-center/profiles/<name>.json
#   profiles.sh list            -> one line per profile:  name|base64(json)
#   profiles.sh save NAME B64   -> write the profile
#   profiles.sh delete NAME
dir="$HOME/.local/share/kontrol-center/profiles"
mkdir -p "$dir"
clean() { printf '%s' "$1" | tr -c 'A-Za-z0-9 ._-' '_' | sed 's/^[. ]*//; s/ *$//'; }
case "$1" in
  list)
    for f in "$dir"/*.json; do
      [ -f "$f" ] || continue
      n=$(basename "$f" .json)
      printf '%s|%s\n' "$n" "$(base64 -w0 "$f")"
    done ;;
  save)
    n=$(clean "$2"); [ -z "$n" ] && exit 1
    printf '%s' "$3" | base64 -d > "$dir/$n.json" ;;
  delete)
    n=$(clean "$2"); [ -z "$n" ] && exit 1
    rm -f "$dir/$n.json" ;;
esac
exit 0
