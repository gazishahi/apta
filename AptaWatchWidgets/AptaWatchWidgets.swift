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
