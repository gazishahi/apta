# October feedback improvements

## Implemented

- Hide the return-to-today button on the current date, preserving its space and excluding it from accessibility navigation.
- Place the city picker below Qibla. Explicitly label manually selected cities.
- Remove the high-latitude selector from onboarding. Keep the existing default and advanced settings controls.
- Persist an explicit request to use current location across the Settings permission detour and app termination. Independent permission changes preserve a manual city; choosing another city cancels a pending switch.
- Show location update, permission-denied, and retry states. Include retry during onboarding when a location fix fails.
- Add a separate rectangular **Five Prayers** Lock Screen widget with abbreviated prayer names, 12/24-hour times, and a date label. The schedule changes at local midnight and retains Isha belonging to the calculation day even when Isha falls after midnight. Existing widgets retain their behavior.

## Verification

- Final simulator build succeeded; all 58 unit tests passed.
- Build and unit tests: `xcodebuild -project apta.xcodeproj -scheme apta -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:aptaTests -parallel-testing-enabled NO test`.
- New tests cover permission intent persistence/cancellation, selected-location midnight, both daylight-saving transitions, and after-midnight Isha in Oslo.
- Simulator visual checks: simplified preferences; bottom city picker; TODAY absent on today, present on tomorrow, and absent after returning.
- Simulator recovery: manual Boston → denied permission → Use Current Location → Open Settings → terminate app → grant permission → relaunch. The pending request completed using simulated San Francisco coordinates.
- Simulator recovery without a manual override: deny permission, change the simulated position to Boston, then grant permission. The permission warning cleared and the city and prayer times updated automatically.
- Rendered the actual widget view with sample data at 153, 160, and 172 points wide in both time formats. These renders verify the compact layout, not system Lock Screen placement.

## Before release

- Check Five Prayers on a physical iPhone Lock Screen, including tinted/Always-On appearance, the longest localized time strings, and midnight rollover.
- Confirm the permission recovery flow on a physical device with real location services.
- Zawwal and broader forbidden-time guidance remain deferred. Define the calculation convention and whether the feature represents an instant or an avoidance interval, then obtain review of the religious guidance.
