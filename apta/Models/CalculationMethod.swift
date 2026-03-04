import Foundation
import Adhan

enum AppCalculationMethod: String, CaseIterable, Codable, Identifiable {
    case muslimWorldLeague = "Muslim World League"
    case egyptian = "Egyptian"
    case karachi = "Karachi"
    case ummAlQura = "Umm al-Qura"
    case dubai = "Dubai"
    case qatar = "Qatar"
    case kuwait = "Kuwait"
    case moonsightingCommittee = "Moonsighting Committee"
    case singapore = "Singapore"
    case northAmerica = "ISNA"
    case tehran = "Tehran"
    case turkey = "Turkey"
    case other = "Other"

    var id: String { rawValue }

    static func suggestedForLocale() -> AppCalculationMethod {
        guard let region = Locale.current.region?.identifier else { return .northAmerica }
        switch region {
        // North America
        case "US", "CA", "MX": return .northAmerica
        // Saudi Arabia
        case "SA": return .ummAlQura
        // UAE
        case "AE": return .dubai
        // Qatar
        case "QA": return .qatar
        // Kuwait
        case "KW": return .kuwait
        // Turkey
        case "TR": return .turkey
        // Iran
        case "IR": return .tehran
        // Singapore, Malaysia, Brunei, Indonesia
        case "SG", "MY", "BN", "ID": return .singapore
        // Egypt, Libya, Sudan
        case "EG", "LY", "SD": return .egyptian
        // Pakistan, Bangladesh, Afghanistan
        case "PK", "BD", "AF": return .karachi
        // Europe, UK, Scandinavia
        case "GB", "DE", "FR", "NL", "BE", "SE", "NO", "DK", "FI", "IS",
             "IT", "ES", "PT", "AT", "CH", "IE", "PL", "CZ", "HU", "RO",
             "BG", "HR", "RS", "BA", "AL", "MK", "ME", "XK", "GR", "LT",
             "LV", "EE":
            return .muslimWorldLeague
        default:
            return .muslimWorldLeague
        }
    }

    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .muslimWorldLeague: return .muslimWorldLeague
        case .egyptian: return .egyptian
        case .karachi: return .karachi
        case .ummAlQura: return .ummAlQura
        case .dubai: return .dubai
        case .qatar: return .qatar
        case .kuwait: return .kuwait
        case .moonsightingCommittee: return .moonsightingCommittee
        case .singapore: return .singapore
        case .northAmerica: return .northAmerica
        case .tehran: return .tehran
        case .turkey: return .turkey
        case .other: return .other
        }
    }
}
