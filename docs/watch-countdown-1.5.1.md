# Watch countdown verification for 1.5.1

The Smart Stack and corner countdowns now use SwiftUI's live time data source
with its bounded system timer format. The corner progress arc also uses a
system-managed timer interval. No widget relies on a `TimelineView` callback
or ten-minute snapshot to advance its remaining-time display.

## Physical Watch / TestFlight checklist

- Install matching iPhone and Watch builds. Add both "apta Pro" (next prayer
  with upcoming) and "apta Pro Countdown" to the Smart Stack.
- Compare them at least 12 minutes apart without opening apta. Their countdowns
  should agree to minute precision and decrease with elapsed time.
- Repeat after lowering the wrist, sleeping/waking the display, and reopening
  the Smart Stack. Check Always On and Low Power Mode separately.
- Check the corner countdown and corner progress arc on a supported watch face.
  Verify text fits for a multi-hour interval as well as under an hour.
- Observe the final minute and a prayer transition. Bounded timers must stop at
  zero, never start counting upward. The next timeline entry should advance the
  prayer names and upcoming times, including Fajr to Sunrise.
- Leave the Watch app visible across a prayer boundary to check its scheduled
  transition. Repeat around midnight and with the phone disconnected.
- Compare the actual prayer times with the iPhone using the same location and
  calculation settings; a mismatch is separate from countdown rendering.

## Expected formatting

Minute-only timers use Apple's localized wording and round down. For example,
19 minutes 37 seconds becomes "19 minutes left"; the last partial minute shows
"0 minutes left". The rectangular and circular second-level timers retain
their clock-style countdowns. Check the longer localized wording for clipping.

Unit tests cover the reporter's two time offsets, timer expiry, precision,
system-scheduled updates, and format serialization. They do not prove WidgetKit
refresh behavior on a physical Watch; complete the checklist before release.
