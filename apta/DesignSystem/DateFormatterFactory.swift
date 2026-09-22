import Foundation

enum DateFormatterFactory {
    private static var formattersCache: [String: DateFormatter] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.gazi.apta.dateformatters", attributes: .concurrent)

    static func make(format: String, locale: Locale? = nil, calendar: Calendar? = nil) -> DateFormatter {
        let isIslamic = calendar?.identifier == .islamicUmmAlQura
        let cacheKey = "\(format)-\(locale?.identifier ?? "default")-\(isIslamic)-\(SharedDefaults.prayerTimeZone.identifier)"

        return cacheQueue.sync(flags: .barrier) {
            if let cached = formattersCache[cacheKey] {
                return cached
            }

            let formatter = DateFormatter()
            formatter.timeZone = SharedDefaults.prayerTimeZone
            formatter.dateFormat = format
            if let locale = locale {
                formatter.locale = locale
            }
            if let calendar = calendar {
                formatter.calendar = calendar
            }

            formattersCache[cacheKey] = formatter
            return formatter
        }
    }

    static func makeIslamic(format: String, locale: Locale = Locale(identifier: "en")) -> DateFormatter {
        let calendar = SharedDefaults.calendar(identifier: .islamicUmmAlQura)
        return make(format: format, locale: locale, calendar: calendar)
    }

    static func clearCache() {
        cacheQueue.async(flags: .barrier) {
            formattersCache.removeAll()
        }
    }
}
