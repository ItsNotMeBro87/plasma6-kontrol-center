#!/bin/bash
# audio.sh dump -> default sink name + JSON of all sinks (playback devices) and sink inputs (application streams).
# Needs `pactl` from PulseAudio or pipewire-pulse, version 16 or newer (for --format=json).
case "$1" in
  dump)
    echo "@@DEFAULT"; timeout 3 pactl get-default-sink 2>/dev/null
    echo "@@SINKS";   timeout 4 pactl --format=json list sinks 2>/dev/null
    echo "@@INPUTS";  timeout 4 pactl --format=json list sink-inputs 2>/dev/null
    ;;
esac
exit 0
