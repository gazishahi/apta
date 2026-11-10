#!/bin/zsh
# Captures raw App Store screenshots from the simulator using the DEBUG-only
# CaptureMode launch arguments (see apta/App/CaptureMode.swift).
#
# Usage: scripts/capture-screenshots.sh <simulator udid> <output dir>
# Build and install a Debug build on the simulator first.
set -euo pipefail

udid=$1 out=${2:A}   # simctl needs an absolute path
clock=${CAPTURE_TIME:-15:33}   # 3:33 PM in New York: Maghrib "in 1h 9m"
bundle=Gazi.apta
mkdir -p "$out"

xcrun simctl location "$udid" set 40.7128,-74.0060
group=$(xcrun simctl get_app_container "$udid" "$bundle" groups | awk '/group.Gazi.apta/ {print $2}')
prefs="$group/Library/Preferences/group.Gazi.apta"

setpref() { xcrun simctl spawn "$udid" defaults write "$prefs" "$@"; }
theme() {
  if [[ -z $1 ]]; then
    xcrun simctl spawn "$udid" defaults delete "$prefs" backgroundTheme 2>/dev/null || true
  else
    setpref backgroundTheme -data $(printf '{"preset":"%s","isAdaptive":true,"preferredVariant":"light"}' "$1" | xxd -p | tr -d '\n')
  fi
}

# shot <name> <light|dark> [launch args...]
shot() {
  local name=$1 appearance=$2; shift 2
  local h=${clock%%:*} m=${clock##*:}
  xcrun simctl ui "$udid" appearance "$appearance"
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  xcrun simctl status_bar "$udid" override --time "$(( (h + 11) % 12 + 1 )):$m" \
    --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
    --batteryState discharging --batteryLevel 100
  xcrun simctl launch "$udid" "$bundle" -CaptureTime "$clock" "$@" > /dev/null
  sleep 10
  # The simulator service can't write into ~/Documents, so capture to a temp file first.
  local tmp=$(mktemp -t apta-capture).png
  xcrun simctl io "$udid" screenshot "$tmp" > /dev/null 2>&1
  mv "$tmp" "$out/$name.png"
  echo "$out/$name.png"
}

setpref hasCompletedOnboarding -bool YES
setpref background_location_choice_made_v1 -bool YES
# Warm-up launch without capture options, so the app saves a location to reuse.
xcrun simctl launch "$udid" "$bundle" > /dev/null
sleep 10
xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
theme ""

shot main_light light
shot main_dark dark
shot settings_light light -CaptureScreen settings
shot settings_dark dark -CaptureScreen settings
shot location_light light -CaptureScreen location -CaptureQuery Istanbul
# Travel: the main screen with Istanbul chosen as a manual location.
setpref manual_location_v1 -data $(printf '{"city":"Istanbul","detail":"Istanbul, Türkiye","latitude":41.0082,"longitude":28.9784,"timeZoneIdentifier":"Europe/Istanbul"}' | xxd -p | tr -d '\n')
shot travel_light light
xcrun simctl spawn "$udid" defaults delete "$prefs" manual_location_v1 2>/dev/null || true
shot qibla_light light -CaptureScreen qibla
shot qibla_dark dark -CaptureScreen qibla
for preset in emerald indigo rose midnight; do
  theme $preset
  shot theme_$preset $([[ $preset == indigo || $preset == midnight ]] && echo dark || echo light)
done

theme ""
xcrun simctl ui "$udid" appearance light
xcrun simctl status_bar "$udid" clear
