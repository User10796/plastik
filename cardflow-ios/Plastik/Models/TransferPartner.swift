import Foundation

// MARK: - Transfer Partner

struct TransferPartner: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: PartnerType
    let alliance: String?
    let partnerAirlines: [String]?

    // Legacy compatibility
    let transferRatio: Double?
    let fromPrograms: [String]?
}

enum PartnerType: String, Codable, Hashable {
    case airline, hotel

    var displayName: String {
        switch self {
        case .airline: return "Airline"
        case .hotel: return "Hotel"
        }
    }

    var icon: String {
        switch self {
        case .airline: return "airplane"
        case .hotel: return "building.2.fill"
        }
    }
}

// MARK: - Points Currency

struct PointsCurrency: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let earnedWith: [String]

    var shortName: String {
        switch id {
        case "chase-ur": return "Chase UR"
        case "amex-mr": return "Amex MR"
        case "citi-typ": return "Citi TYP"
        case "capital-one": return "Cap One"
        default: return name
        }
    }
}

// MARK: - Transfer Route

struct TransferRoute: Codable, Identifiable, Hashable {
    let id: String
    let fromCurrency: String
    let toPartner: String
    let ratio: Double
    let transferTime: TransferTime
    let minimumTransfer: Int
    let transferBonus: TransferBonus?
}

enum TransferTime: String, Codable, Hashable {
    case instant
    case sameDay
    case oneToTwoDays
    case twoToThreeDays
    case threeToFiveDays
    case oneWeekPlus

    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .sameDay: return "Same day"
        case .oneToTwoDays: return "1-2 days"
        case .twoToThreeDays: return "2-3 days"
        case .threeToFiveDays: return "3-5 days"
        case .oneWeekPlus: return "1 week+"
        }
    }
}

struct TransferBonus: Codable, Hashable {
    let bonusPercent: Int
    let startDate: Date
    let endDate: Date
    let description: String

    var isActive: Bool {
        Date() >= startDate && Date() <= endDate
    }
}

// MARK: - Downgrade Paths & Historical Bonuses

struct DowngradePath: Codable, Identifiable, Hashable {
    let id: String
    let fromCard: String
    let toCards: [DowngradeOption]
}

struct DowngradeOption: Codable, Hashable {
    let cardId: String
    let benefits: [String]
    let considerations: [String]
}

struct HistoricalBonus: Codable, Identifiable, Hashable {
    let id: String
    let cardId: String
    let bonusHistory: [BonusHistoryEntry]
    let typicalRange: String
    let recommendation: String
}

struct BonusHistoryEntry: Codable, Hashable {
    let date: String
    let points: Int
    let spend: Int
}
