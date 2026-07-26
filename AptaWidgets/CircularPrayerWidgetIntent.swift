import AppIntents
import WidgetKit

enum CircularPrayerDisplayMode: String, AppEnum {
    case time
    case countdown

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Display"
    }

    static var caseDisplayRepresentations: [CircularPrayerDisplayMode: DisplayRepresentation] {
        [
            .time: "Prayer Time",
            .countdown: "Countdown"
        ]
    }
}

struct CircularPrayerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Prayer Gauge" }
    static var description: IntentDescription { "Choose what the circular prayer widget shows." }

    @Parameter(title: "Display", default: .time)
    var displayMode: CircularPrayerDisplayMode
}

struct ConfigurablePrayerTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = PrayerWidgetEntry
    typealias Intent = CircularPrayerWidgetIntent

    private let provider = PrayerTimelineProvider()

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        provider.placeholder(in: context)
    }

    func snapshot(for configuration: CircularPrayerWidgetIntent, in context: Context) async -> PrayerWidgetEntry {
        await withCheckedContinuation { continuation in
            provider.getSnapshot(in: context) { entry in
                continuation.resume(returning: entry.withCircularDisplayMode(configuration.displayMode))
            }
        }
    }

    func timeline(for configuration: CircularPrayerWidgetIntent, in context: Context) async -> Timeline<PrayerWidgetEntry> {
        await withCheckedContinuation { continuation in
            provider.getTimeline(in: context) { timeline in
                let entries = timeline.entries.map {
                    $0.withCircularDisplayMode(configuration.displayMode)
                }
                continuation.resume(returning: Timeline(entries: entries, policy: timeline.policy))
            }
        }
    }
}

private extension PrayerWidgetEntry {
    func withCircularDisplayMode(_ displayMode: CircularPrayerDisplayMode) -> PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: date,
            currentPrayer: currentPrayer,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime,
            previousPrayerTime: previousPrayerTime,
            progressStartTime: progressStartTime,
            progressEndTime: progressEndTime,
            allPrayers: allPrayers,
            hijriDateString: hijriDateString,
            locationName: locationName,
            hasLocation: hasLocation,
            circularDisplayMode: displayMode
        )
    }
}
