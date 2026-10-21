#!/bin/bash
# Installs (or updates) Kontrol Center for the current user
cd "$(dirname "$0")"
chmod +x org.kontrol.center/contents/scripts/*.sh get-tabler-icons.sh
./get-tabler-icons.sh
kpackagetool6 -t Plasma/Applet -u org.kontrol.center 2>/dev/null || kpackagetool6 -t Plasma/Applet -i org.kontrol.center
echo
echo "Done. Restart Plasma to load the update:  kquitapp6 plasmashell; kstart plasmashell"
echo "Then right-click the widget > Configure Kontrol Center... to change colours, shapes and buttons."
