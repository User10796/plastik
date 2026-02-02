import Foundation

struct CardBenefit: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let value: Double
    let resetPeriod: ResetPeriod
    let category: SpendCategory

    var formattedValue: String {
        if value == 0 { return "Included" }
        return "$\(Int(value))"
    }
}

enum ResetPeriod: String, Codable, Hashable {
    case monthly, quarterly, annual, calendarYear, none

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annual: return "Annual"
        case .calendarYear: return "Calendar Year"
        case .none: return "One-time"
        }
    }
}
