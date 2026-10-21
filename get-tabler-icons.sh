#!/bin/bash
# Downloads the real Tabler Icons (outline, MIT licence) over the bundled fallback icons.
# Safe to run any time. Icons that fail to download simply keep their fallback.
cd "$(dirname "$0")/org.kontrol.center/contents/icons" || exit 1
command -v curl >/dev/null 2>&1 || { echo "curl not found - keeping bundled icons."; exit 0; }
ok=0; kept=0
for f in *.svg; do
  case "$f" in kc-*) continue ;; esac
  name="${f%.svg}"
  tmp=$(mktemp)
  for url in "https://cdn.jsdelivr.net/npm/@tabler/icons@3/icons/outline/$name.svg" \
             "https://raw.githubusercontent.com/tabler/tabler-icons/main/icons/outline/$name.svg"; do
    if curl -fsSL --max-time 10 "$url" -o "$tmp" 2>/dev/null && grep -q "<svg" "$tmp"; then
      sed -i 's/currentColor/#000000/g' "$tmp"
      mv "$tmp" "$f"; ok=$((ok+1)); tmp=""; break
    fi
  done
  if [ -n "$tmp" ]; then rm -f "$tmp"; kept=$((kept+1)); echo "  kept fallback for: $name"; fi
done
echo "Tabler icons: $ok downloaded, $kept kept as fallback."
