import Foundation
import Adhan

enum PrayerName: String, CaseIterable, Identifiable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"
    case ishraq = "Ishraq"

    var id: String { rawValue }

    /// Canonical 3-letter abbreviation, used everywhere a compact label is needed.
    var shortLabel: String {
        switch self {
        case .fajr: return "FJR"
        case .sunrise: return "SUN"
        case .dhuhr: return "DHR"
        case .asr: return "ASR"
        case .maghrib: return "MGB"
        case .isha: return "ISH"
        case .ishraq: return "ISQ"
        }
    }

    /// Label for watch corner complications: full name, except the longest
    /// names which fall back to the canonical abbreviation.
    var cornerLabel: String {
        switch self {
        case .maghrib, .sunrise, .ishraq: return shortLabel
        default: return rawValue.uppercased()
        }
    }

    var adhanPrayer: Prayer {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        case .ishraq: return .sunrise
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
    let supplementalTime: PrayerSupplementalTime?

    init(name: PrayerName, time: Date, supplementalTime: PrayerSupplementalTime? = nil) {
        self.name = name
        self.time = time
        self.supplementalTime = supplementalTime
    }
}

struct PrayerSupplementalTime {
    let label: String
    let time: Date
}
