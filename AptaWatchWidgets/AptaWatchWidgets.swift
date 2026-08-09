import WidgetKit
import SwiftUI

struct AptaInlineComplication: Widget {
    let kind = "AptaInlineComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            InlineComplicationView(entry: entry)
        }
        .configurationDisplayName("apta")
        .description("Next prayer time")
        .supportedFamilies([.accessoryInline])
    }
}

struct AptaCircularComplication: Widget {
    let kind = "AptaCircularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            CircularComplicationView(entry: entry)
        }
        .configurationDisplayName("apta")
        .description("Next prayer countdown")
        .supportedFamilies([.accessoryCircular])
    }
}

struct AptaCircularProgressComplication: Widget {
    let kind = "AptaCircularProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            CircularProgressComplicationView(entry: entry)
        }
        .configurationDisplayName("apta Pro Progress")
        .description("Progress ring toward the next prayer")
        .supportedFamilies([.accessoryCircular])
    }
}

struct AptaRectangularComplication: Widget {
    let kind = "AptaRectangularComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            RectangularComplicationView(entry: entry)
        }
        .configurationDisplayName("apta Pro")
        .description("Next prayer with upcoming")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct AptaCornerComplication: Widget {
    let kind = "AptaCornerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            CornerComplicationView(entry: entry)
        }
        .configurationDisplayName("apta Pro")
        .description("Prayer name and time")
        .supportedFamilies([.accessoryCorner])
    }
}

struct AptaCornerProgressComplication: Widget {
    let kind = "AptaCornerProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            CornerProgressComplicationView(entry: entry)
        }
        .configurationDisplayName("apta Pro Progress")
        .description("Prayer progress arc")
        .supportedFamilies([.accessoryCorner])
    }
}

struct AptaCornerCountdownComplication: Widget {
    let kind = "AptaCornerCountdownComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            CornerCountdownComplicationView(entry: entry)
        }
        .configurationDisplayName("apta Pro Countdown")
        .description("Prayer countdown")
        .supportedFamilies([.accessoryCorner])
    }
}
