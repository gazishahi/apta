#!/bin/zsh
# Build the watch app and push it to the watch simulator in one shot.
# Usage: scripts/watch-sim-refresh.sh [watch-sim-udid]
set -e

UDID="${1:-FFBFFA01-0639-4D7A-B8F7-EA1BC7D3A1F6}"   # Apple Watch Series 11 (46mm)
BUNDLE_ID="Gazi.apta.watchkitapp"

cd "$(dirname "$0")/.."

xcodebuild -project apta.xcodeproj -scheme 'AptaWatch Watch App' \
  -destination "generic/platform=watchOS Simulator" build -quiet

APP=$(echo ~/Library/Developer/Xcode/DerivedData/apta-*/Build/Products/Debug-watchsimulator/AptaWatch\ Watch\ App.app)

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a Simulator
xcrun simctl install "$UDID" "$APP"
xcrun simctl privacy "$UDID" grant location-always "$BUNDLE_ID"
xcrun simctl location "$UDID" set 40.7128,-74.0060
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID"
echo "✓ installed and launched on $(xcrun simctl list devices | grep "$UDID" | sed 's/(.*//' | xargs)"
