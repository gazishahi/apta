import Foundation

enum NotificationMessages {

    // MARK: - Fun Messages

    static let fajrMessages = [
        "Fajr is here. The blankets make a strong case, though.",
        "Yes, it's early. Yes, it's worth it.",
        "A quiet world. A very persuasive pillow. Time for Fajr.",
        "The group chats can sleep. It's Fajr.",
        "Small yawn. Deep breath. Fajr.",
        "Your morning has an opening act: Fajr.",
        "Bed hair is welcome. It's Fajr.",
        "Fajr first. The to-do list hasn't found you yet.",
    ]

    static let dhuhrMessages = [
        "Lunch break? Prayer break.",
        "Step away from the screen.",
        "Your tabs will still be there after Dhuhr. All of them.",
        "Dhuhr. Aka the midday reset button.",
        "Dhuhr is here. Give your to-do list a little intermission.",
        "A little less scrolling. A little more stillness. Dhuhr.",
        "Pause the busy. It's Dhuhr.",
        "Dhuhr: a different kind of standing appointment.",
    ]

    static let asrMessages = [
        "The afternoon has a plot twist: a pause for Asr.",
        "Asr is here. Your errands can take a breather too.",
        "A full afternoon deserves a little stillness. Asr.",
        "Asr: your afternoon intermission, no ticket needed.",
        "Your phone just reminded you to pray. What a time to be alive.",
        "The to-do list is doing its thing. Time for Asr.",
        "Asr is here. A good moment to put the phone down.",
    ]

    static let maghribMessages = [
        "Sun's gone. You know the drill.",
        "The sun has signed off. It's Maghrib.",
        "The sky is changing outfits. Time for Maghrib.",
        "Sunset comes with a reminder: Maghrib.",
        "A change of scenery. A moment for Maghrib.",
        "Maghrib is here. Evening has entered the chat.",
        "The day's turning a page. Time for Maghrib.",
        "Instagram sunset pic can wait."
    ]

    static let ishaMessages = [
        "Last one of the day. You got this.",
        "Isha is here. A little stillness before the wind-down.",
        "The day's closing credits. Pray through them.",
        "The pillow has plans. First, a moment for Isha.",
        "The night is dark, but Isha brings light.",
        "Isha: a quieter kind of night mode.",
        "One last prayer reminder. No cliffhanger tonight.",
        "Isha is here. The next episode can stay queued."
    ]

    static let ishraqMessages = [
        "Ishraq time. An optional pause before the day picks up speed.",
        "Room for a little stillness? It's Ishraq time.",
        "Ishraq is here. An optional addition to your morning routine.",
        "The morning has a little breathing room. A moment for Ishraq, if you like.",
        "Ishraq time. A gentle invitation, no calendar invite needed.",
        "An optional morning pause, with fewer notifications. Ishraq.",
        "Ishraq is here, if you'd like a moment away from the bustle.",
    ]

    static let sunriseMessages = [
        "Sunrise. The day is officially showing off.",
        "Sunrise is here. Nature has switched on the lights.",
        "The sun has clocked in. Good morning.",
        "Sunrise. A fresh page, no loading screen.",
        "Daylight has arrived. No subscription required.",
        "Sunrise. The sky's morning update is in.",
    ]

    // MARK: - Ramadan Messages

    // These arrive at Fajr, never as an invitation to keep eating.
    static let ramadanFajrMessages = [
        "Suhoor has ended. Time for Fajr. The kitchen can take a breather.",
        "Suhoor has ended. Fajr is here, bed hair and all.",
        "Suhoor has ended. Time for Fajr. A quiet start before the busy.",
        "Suhoor has ended. Fajr is here. The group chats can wait.",
        "Suhoor has ended. Time for Fajr. Small yawn, deep breath.",
        "Suhoor has ended. Fajr is here. The dishes aren't going anywhere.",
    ]

    static let iftarMessages = [
        "Iftar and Maghrib are here. A date worth looking forward to.",
        "Time for iftar and Maghrib. The table's moment has arrived.",
        "Iftar and Maghrib are here. Water, meet your biggest fan.",
        "Time for iftar and Maghrib. The first sip gets a warm welcome.",
        "Iftar and Maghrib are here. The food photos can wait.",
        "Time for iftar and Maghrib. A little less waiting, a little more gratitude.",
        "Iftar and Maghrib are here. Today's dinner has an opening ceremony.",
        "Time for iftar and Maghrib. A lovely reason to gather round.",
    ]

    // MARK: - Message Selection

    static func prayerMessage(for prayer: PrayerName, time: Date, date: Date,
                              isRamadan: Bool, settings: PrayerSettings) -> String {
        if settings.notificationStyle == .simple {
            let message = simpleMessage(for: prayer, time: time, settings: settings)
            return isRamadan && prayer == .fajr ? "Suhoor has ended. \(message)" : message
        }
        return funMessage(for: prayer, date: date, isRamadan: isRamadan)
    }

    static func funMessage(for prayer: PrayerName, date: Date, isRamadan: Bool) -> String {
        if isRamadan {
            if prayer == .fajr {
                return seededPick(from: ramadanFajrMessages, prayer: prayer, date: date)
            }
            if prayer == .maghrib {
                return seededPick(from: iftarMessages, prayer: prayer, date: date)
            }
        }

        let pool: [String]
        switch prayer {
        case .fajr: pool = fajrMessages
        case .dhuhr: pool = dhuhrMessages
        case .asr: pool = asrMessages
        case .maghrib: pool = maghribMessages
        case .isha: pool = ishaMessages
        case .ishraq: pool = ishraqMessages
        case .sunrise: pool = sunriseMessages
        }
        return seededPick(from: pool, prayer: prayer, date: date)
    }

    static func boundaryMessage(label: String, prayer: PrayerName, time: Date, settings: PrayerSettings) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        let timeStr = formatter.string(from: time)
        switch label {
        case "ends":
            return "\(prayer.rawValue) time is ending at \(timeStr)"
        case "best before":
            return "Best time for \(prayer.rawValue) is ending at \(timeStr)"
        default:
            return "It's \(timeStr)"
        }
    }

    static func preMessage(for prayer: PrayerName, minutes: Int, time: Date, settings: PrayerSettings,
                           isRamadan: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        let timing = "\(minutes) minutes until \(prayer.rawValue) at \(formatter.string(from: time))"
        if isRamadan && prayer == .fajr {
            return settings.notificationStyle == .fun
                ? "\(timing). Time to wrap up suhoor. The kitchen's closing act."
                : "\(timing). Time to wrap up suhoor."
        }
        guard settings.notificationStyle == .fun else { return timing }
        let nudge: String
        switch prayer {
        case .fajr: nudge = "Give the blankets a little notice."
        case .dhuhr: nudge = "Find a good stopping point. Your tabs can hold the fort."
        case .asr: nudge = "An intermission for your afternoon is on its way."
        case .maghrib:
            nudge = isRamadan ? "Iftar is coming. The table's almost on stage." : "Evening is waiting in the wings."
        case .isha: nudge = "A heads-up for you and your pillow."
        case .sunrise, .ishraq: return timing
        }
        return "\(timing). \(nudge)"
    }

    static func simpleMessage(for prayer: PrayerName, time: Date, settings: PrayerSettings) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return "It's time for \(prayer.rawValue) (\(formatter.string(from: time)))"
    }

    /// Date-seeded pick so same day = same message (no duplicates on reschedule)
    private static func seededPick(from pool: [String], prayer: PrayerName, date: Date) -> String {
        guard !pool.isEmpty else { return "" }
        let cal = SharedDefaults.prayerCalendar
        let day = cal.ordinality(of: .day, in: .era, for: date) ?? 0
        // Unlike Swift's randomized hashValue, this stays stable across launches.
        let offset = prayer.rawValue.utf8.reduce(0) { $0 + Int($1) }
        let remainder = (day % pool.count + offset % pool.count) % pool.count
        let index = (remainder + pool.count) % pool.count
        return pool[index]
    }
}
