import Foundation

enum NotificationMessages {

    // MARK: - Fun Messages

    static let fajrMessages = [
        "Your bed is lying to you. Get up.",
        "Yes it's early. Yes it's worth it.",
        "Fajr alarm > regular alarm.",
        "The snooze button is not your friend right now.",
        "Technically you could sleep in. But you won't.",
        "4 AM you is stronger than 4 AM you thinks.",
        "Cold water, wudu, go.",
        "If you're reading this, you're already awake. Might as well.",
    ]

    static let dhuhrMessages = [
        "Lunch break? Prayer break.",
        "Step away from the screen.",
        "Your meeting can wait. This one can't.",
        "Dhuhr. Aka the midday reset button.",
        "Quick break from pretending to be productive.",
        "The sun is literally right above you. Take the hint.",
        "Alt+Tab to prayer real quick.",
        "Sandwich after. Salah first.",
    ]

    static let asrMessages = [
        "The 3 PM slump is real. Asr is realer.",
        "You forgot about Asr didn't you. It's okay, that's why I'm here.",
        "Afternoon vibes. Prayer vibes.",
        "This is your Asr reminder before you get busy and forget.",
        "Between Dhuhr and Maghrib there's this one. Don't skip it.",
        "Asr: the prayer that separates the casuals from the committed.",
        "Your phone just reminded you to pray. What a time to be alive.",
        "Yes, again. That's kind of the whole point.",
    ]

    static let maghribMessages = [
        "Sun's gone. You know the drill.",
        "Golden hour is over. Maghrib hour begins.",
        "The sky is doing its thing. You do yours.",
        "Sunset prayer. No filter needed.",
        "Day shift is over. Pray and clock out.",
        "Maghrib waits for no one. Literally, it's a short window.",
        "The sky turned orange for you. Least you can do.",
        "Three down, two to go.",
    ]

    static let ishaMessages = [
        "Last one of the day. You got this.",
        "Isha before Netflix. You know the rules.",
        "One more and you're done. For today, at least.",
        "The day's closing credits. Pray through them.",
        "Don't fall asleep before this one. I'm watching.",
        "Isha: because the day doesn't end at Maghrib.",
        "Toothbrush can wait 5 minutes.",
        "Final boss of the daily prayers. Let's go.",
    ]

    // MARK: - Ramadan Messages

    static let suhoorMessages = [
        "Alright, stop eating now.",
        "Last bite. I mean it.",
        "Chug that water like your life depends on it. Because your afternoon does.",
        "Suhoor is closing. This is your 'kitchen is closed' announcement.",
        "You have mass-texted everyone 'suhoor?' and now it's actually time.",
        "Eat something. Anything. You'll thank yourself at 2 PM.",
        "Fajr is coming and it's bringing a long day with it. Fuel up.",
        "That leftover biryani isn't going to eat itself. Hurry.",
    ]

    static let iftarMessages = [
        "Go eat. You've earned it.",
        "Oily food: incoming this iftar.",
        "The longest day of your life is over. Again. Tomorrow you do it again.",
        "Date first. Then everything else. You know the order.",
        "Your stomach has been filing complaints all day. Time to respond.",
        "Iftar time. Try not to eat everything in the first 3 minutes.",
        "You survived. Reward yourself. Responsibly.",
        "The samosas have been waiting for you.",
    ]

    // MARK: - Message Selection

    static func funMessage(for prayer: PrayerName, date: Date, isRamadan: Bool) -> String {
        if isRamadan {
            if prayer == .fajr {
                return seededPick(from: suhoorMessages, prayer: prayer, date: date)
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
        case .sunrise: return ""
        }
        return seededPick(from: pool, prayer: prayer, date: date)
    }

    static func simpleMessage(for prayer: PrayerName, time: Date, settings: PrayerSettings) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return "It's time for \(prayer.rawValue) — \(formatter.string(from: time))"
    }

    /// Date-seeded pick so same day = same message (no duplicates on reschedule)
    private static func seededPick(from pool: [String], prayer: PrayerName, date: Date) -> String {
        guard !pool.isEmpty else { return "" }
        let cal = Calendar(identifier: .gregorian)
        let day = cal.ordinality(of: .day, in: .era, for: date) ?? 0
        let hash = day &+ prayer.rawValue.hashValue
        let index = abs(hash) % pool.count
        return pool[index]
    }
}
