#!/bin/zsh
# Captures raw Apple Watch screenshots from the watch simulator using the
# DEBUG-only CaptureMode launch arguments (see apta/App/CaptureMode.swift).
#
# Usage: scripts/capture-watch-screenshots.sh <watch simulator udid> <output dir>
# Build and install a Debug build of "AptaWatch Watch App" on the simulator first.
# watchOS simulators can't override the status bar clock; the render step covers it.
set -euo pipefail

udid=$1 out=${2:A}
clock=${CAPTURE_TIME:-15:33}
bundle=Gazi.apta.watchkitapp
mkdir -p "$out"

xcrun simctl location "$udid" set 40.7128,-74.0060
group=$(xcrun simctl get_app_container "$udid" "$bundle" groups | awk '/group.Gazi.apta/ {print $2}')
prefs="$group/Library/Preferences/group.Gazi.apta"
# Qibla is an apta pro feature on Watch.
xcrun simctl spawn "$udid" defaults write "$prefs" isProUser -bool YES
xcrun simctl spawn "$udid" defaults write "$prefs" proStatusUpdatedAt -float 9999999999

# shot <name> [launch args...]
shot() {
  local name=$1; shift
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  xcrun simctl launch "$udid" "$bundle" "$@" > /dev/null
  sleep 8
  # The simulator service can't write into ~/Documents, so capture to a temp file first.
  local tmp=$(mktemp -t apta-capture).png
  xcrun simctl io "$udid" screenshot "$tmp" > /dev/null 2>&1
  mv "$tmp" "$out/$name.png"
  echo "$out/$name.png"
}

shot times -CaptureTime "$clock"
shot after_isha -CaptureTime 19:30
shot qibla -CaptureTime "$clock" -CaptureScreen qibla
