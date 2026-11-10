#!/bin/zsh
# Captures raw iPhone Duo screenshots (outer display folded, inner display open)
# using the DEBUG-only CaptureMode launch arguments (see apta/App/CaptureMode.swift).
#
# Usage: scripts/capture-duo-screenshots.sh <duo simulator udid> <output dir>
# Requirements: a Debug build installed on the iPhone Duo simulator, Device Hub
# open with that simulator showing, and Accessibility permission for the terminal
# (folding is done by pressing Device Hub's Closed/Open buttons).
set -euo pipefail

udid=$1 out=${2:A}
clock=${CAPTURE_TIME:-15:33}
bundle=Gazi.apta
mkdir -p "$out/outer" "$out/inner"

xcrun simctl location "$udid" set 40.7128,-74.0060
group=$(xcrun simctl get_app_container "$udid" "$bundle" groups | awk '/group.Gazi.apta/ {print $2}')
prefs="$group/Library/Preferences/group.Gazi.apta"
setpref() { xcrun simctl spawn "$udid" defaults write "$prefs" "$@"; }
unsetpref() { xcrun simctl spawn "$udid" defaults delete "$prefs" "$1" 2>/dev/null || true; }

# Folds or unfolds the Duo ("Closed" or "Open"). Device Hub shows either pose
# buttons or a hinge-angle slider (0° closed, 180° open), so handle both.
press() {
  osascript - "$1" > /dev/null <<'APPLESCRIPT'
on run argv
  set pose to item 1 of argv
  tell application "System Events" to tell process "DeviceHub"
    set area to group 3 of splitter group 1 of group 1 of splitter group 1 of group 1 of window 1
    repeat with b in buttons of area
      if (help of b as text) is pose then
        click b
        return
      end if
    end repeat
    if (count of sliders of area) > 0 then
      if pose is "Closed" then
        set value of slider 1 of area to 0
      else
        set value of slider 1 of area to 180
      end if
      return
    end if
    error "Device Hub has no \"" & pose & "\" control. Show the iPhone Duo simulator in Device Hub first."
  end tell
end run
APPLESCRIPT
  sleep 4
}

# Selects the iPhone Duo in Device Hub's sidebar and shows its display.
show_duo() {
  open -g -a DeviceHub
  sleep 3
  osascript > /dev/null <<'APPLESCRIPT'
tell application "System Events" to tell process "DeviceHub"
  set ol to outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of splitter group 1 of group 1 of window 1
  repeat with r in rows of ol
    try
      if (value of static text 1 of UI element 1 of r) is "iPhone Duo" then set selected of r to true
    end try
  end repeat
  delay 3
  set area to group 3 of splitter group 1 of group 1 of splitter group 1 of group 1 of window 1
  set helps to {}
  repeat with b in buttons of area
    set end of helps to (help of b as text)
  end repeat
  -- Before the display is shown, the area only holds the device card's button.
  if helps does not contain "Closed" and (count of sliders of area) is 0 then click button 1 of area
end tell
APPLESCRIPT
  sleep 5
}

# shot <outer|inner> <name> <light|dark> [launch args...]
shot() {
  local display=$1 name=$2 appearance=$3; shift 3
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
  xcrun simctl io "$udid" screenshot --display=$([[ $display == outer ]] && echo primary || echo primary-1) "$tmp" > /dev/null 2>&1
  mv "$tmp" "$out/$display/$name.png"
  echo "$out/$display/$name.png"
}

theme() {
  if [[ -z $1 ]]; then
    unsetpref backgroundTheme
  else
    setpref backgroundTheme -data $(printf '{"preset":"%s","isAdaptive":true,"preferredVariant":"light"}' "$1" | xxd -p | tr -d '\n')
  fi
}

show_duo
setpref hasCompletedOnboarding -bool YES
setpref background_location_choice_made_v1 -bool YES
# Warm-up launch without capture options, so the app saves a location to reuse.
xcrun simctl launch "$udid" "$bundle" > /dev/null
sleep 10
xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
theme ""

# The open phone must be in its natural pose (inner display landscape, 2853 x 2007).
press Open
probe=$(mktemp -t apta-probe).png
xcrun simctl io "$udid" screenshot --display=primary-1 "$probe" > /dev/null 2>&1
if [[ $(sips -g pixelWidth "$probe" | awk '/pixelWidth/ {print $2}') != 2853 ]]; then
  echo "The Duo is turned. Use Device Hub's Rotate button until the open inner display is landscape, then rerun." >&2
  exit 1
fi
rm -f "$probe"

for display in outer inner; do
  press $([[ $display == outer ]] && echo Closed || echo Open)
  shot $display main_light light
  shot $display main_dark dark
  shot $display qibla_dark dark -CaptureScreen qibla
  shot $display qibla_light light -CaptureScreen qibla
done

# Inner-only extras: travel and a color theme.
setpref manual_location_v1 -data $(printf '{"city":"Istanbul","detail":"Istanbul, Türkiye","latitude":41.0082,"longitude":28.9784,"timeZoneIdentifier":"Europe/Istanbul"}' | xxd -p | tr -d '\n')
shot inner travel_light light
unsetpref manual_location_v1
theme emerald
shot inner theme_emerald light
theme ""

press Closed
xcrun simctl ui "$udid" appearance light
xcrun simctl status_bar "$udid" clear
