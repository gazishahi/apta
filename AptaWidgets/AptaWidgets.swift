import WidgetKit
import SwiftUI

struct PrayerWidget: Widget {
    let kind = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerWidgetSwitcher(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetContainerBackground()
                }
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

struct WidgetContainerBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let color = backgroundColor {
            color
        } else {
            Color(uiColor: .systemBackground)
        }
    }

    private var backgroundColor: Color? {
        let theme = WidgetBackgroundTheme.current
        guard WidgetBackgroundTheme.isProUser, let preset = theme.preset else {
            return nil
        }
        if theme.isAdaptive {
            return colorScheme == .dark ? preset.darkColor : preset.lightColor
        }
        return theme.preferredVariant == .dark ? preset.darkColor : preset.lightColor
    }
}

@main
struct AptaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        InlinePrayerWidget()
        CircularPrayerWidget()
        RectangularPrayerWidget()
    }
}
