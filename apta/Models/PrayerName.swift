import Foundation
import Adhan

enum PrayerName: String, CaseIterable, Identifiable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var id: String { rawValue }

    var adhanPrayer: Prayer {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }

    init(from prayer: Prayer) {
        switch prayer {
        case .fajr: self = .fajr
        case .sunrise: self = .sunrise
        case .dhuhr: self = .dhuhr
        case .asr: self = .asr
        case .maghrib: self = .maghrib
        case .isha: self = .isha
        }
    }
}

struct PrayerTimeEntry: Identifiable {
    let id = UUID()
    let name: PrayerName
    let time: Date
}
