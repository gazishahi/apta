import WidgetKit
import SwiftUI

// MARK: - Home Screen Widget (resizable between small/medium/large)

struct PrayerWidget: Widget {
    let kind = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerWidgetSwitcher(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Prayer times for your location.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PrayerWidgetSwitcher: View {
    @Environment(\.widgetFamily) var family
    let entry: PrayerWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPrayerWidgetView(entry: entry)
        case .systemMedium:
            MediumPrayerWidgetView(entry: entry)
        case .systemLarge:
            LargePrayerWidgetView(entry: entry)
        default:
            SmallPrayerWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widgets

struct InlinePrayerWidget: Widget {
    let kind = "InlinePrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            InlinePrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Prayer Inline")
        .description("Next prayer name and time.")
        .supportedFamilies([.accessoryInline])
    }
}

struct CircularPrayerWidget: Widget {
    let kind = "CircularPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            CircularPrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Gauge")
        .description("Next prayer with progress gauge.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct RectangularPrayerWidget: Widget {
    let kind = "RectangularPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            RectangularPrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Countdown")
        .description("Next prayer with progress bar.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Widget Bundle

@main
struct AptaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        InlinePrayerWidget()
        CircularPrayerWidget()
        RectangularPrayerWidget()
    }
}
