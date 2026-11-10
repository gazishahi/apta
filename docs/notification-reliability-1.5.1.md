# Notification reliability

## Cause and behavior

The previous scheduler queued only today and the next two days. Without another
foreground launch or location update, those one-shot notifications ran out.
Location permission set to Never is not a notification permission restriction.

The scheduler now calculates up to 30 days and queues the earliest 60 alerts,
leaving headroom below the historically documented 64-notification limit.
With five daily prayer alerts this covers approximately 12 days. Early reminders,
sunrise, Ishraq, and boundary alerts consume slots and shorten that coverage.
An early reminder at the capacity boundary is omitted if its prayer alert cannot
fit. Unrelated pending notifications also count toward the 60-request budget.

A registered BGAppRefreshTask requests replenishment with an earliest start six
hours later. iOS decides if and when to run it. It uses the persisted manual city
or last known coordinates, without requesting GPS or changing location permissions.
Foreground activation, onboarding completion, settings changes, and location
updates also replenish the queue. No new user-facing setting is introduced.

This is not a guarantee of indefinite notifications without opening the app.
Background App Refresh being disabled, force-quitting, Low Power Mode, or iOS
scheduling decisions can prevent replenishment. Already scheduled notifications
do not depend on the refresh task running. Cached coordinates do not follow
travel when location access is unavailable.

## Queue safety

- Updates are serialized; newer settings supersede unfinished older updates.
- Explicit cancellation is a barrier, including switching away from a manual city.
- Matching unchanged requests are retained without resubmission.
- Matching changed requests are replaced in place; the queue is not cleared first.
- Missing location or denied notification authorization does not erase the queue.
- Submission errors are logged, and pending identifiers are checked after updates.
- Expiration cancels further queue work; a later update can finish replenishment.

OSLog categories are `Notifications` and `NotificationRefresh`, subsystem `Gazi.apta`.
Diagnostic values in standard UserDefaults are `notificationQueueLastChecked`,
`notificationQueueCount`, `notificationQueueScheduledThrough`,
`notificationQueueLastUpdateSucceeded`, and `notificationQueueSubmissionFailures`.
These reflect scheduling, not proof that iOS displayed a notification.

## Device QA before release

Install a build containing this fix and launch apta once. Verify that apta appears
under Settings > General > Background App Refresh. Check both a fresh install and
an upgrade from the previous build. The packaged iPhone app must contain
`UIBackgroundModes: [fetch]` and the permitted refresh-task identifier; these
entries belong to the iPhone target, not the Watch target.

1. Select a manual city, enable prayer alerts, and set iOS location access to Never.
   Confirm upcoming pending requests extend beyond three days and use that city's
   timezone. Repeat with a previously cached automatic location.
2. Leave the app unopened beyond the old three-day window. Confirm prayer alerts
   continue. Check logs for background refresh and a later scheduled-through date.
3. Test with Background App Refresh disabled and separately after force-quitting.
   Existing queued alerts should remain, but replenishment must not be assumed.
4. Enable all optional alert types. Confirm requests remain bounded and ordered,
   and early reminders are paired with their actual prayer alerts.
5. Change manual city, timezone, calculation method, and notification style. Check
   updated times/copy and that disabled events and old-city alerts are removed.
6. Disable all notifications while an update is running. Confirm no prayer alerts
   remain. Re-enable and confirm the queue is rebuilt.
7. Use Xcode's background-task simulation on a connected device to invoke the
   registered task and expiration path. Verify the next refresh request and queue
   diagnostics. Simulation does not establish real-world launch frequency.

Automated tests cover capacity, chronological ordering across DST, pre-alert
pairing, saved/manual coordinates, refill, failed and silently dropped submissions,
concurrent updates, cancellation, idempotence, and packaged background configuration.
