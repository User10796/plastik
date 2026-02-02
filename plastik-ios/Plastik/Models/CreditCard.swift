import Foundation

struct CreditCard: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let issuer: Issuer
    let network: CardNetwork
    let annualFee: Int
    let signupBonus: SignupBonus?
    let earningRates: [EarningRate]
    let benefits: [CardBenefit]
    let transferPartners: [String]
    let churnRules: ChurnRuleRef
    let referralLink: String?
    let imageURL: String?
    let lastUpdated: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CreditCard, rhs: CreditCard) -> Bool {
        lhs.id == rhs.id
    }
}

enum Issuer: String, Codable, CaseIterable, Identifiable {
    case chase, amex, citi, capitalOne, barclays,
         usBank, wellsFargo, bankOfAmerica, discover

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chase: return "Chase"
        case .amex: return "American Express"
        case .citi: return "Citi"
        case .capitalOne: return "Capital One"
        case .barclays: return "Barclays"
        case .usBank: return "US Bank"
        case .wellsFargo: return "Wells Fargo"
        case .bankOfAmerica: return "Bank of America"
        case .discover: return "Discover"
        }
    }
}

enum CardNetwork: String, Codable, CaseIterable {
    case visa, mastercard, amex, discover

    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "Amex"
        case .discover: return "Discover"
        }
    }
}

struct SignupBonus: Codable, Hashable {
    let points: Int
    let currency: String
    let spendRequired: Int
    let timeframeDays: Int
    let expirationDate: Date?
}

struct EarningRate: Codable, Identifiable, Hashable {
    let id: String
    let category: SpendCategory
    let multiplier: Double
    let cap: Int?
    let capPeriod: CapPeriod?
}

enum CapPeriod: String, Codable, Hashable {
    case monthly, quarterly, annual, calendarYear
}

enum SpendCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case dining, travel, groceries, gas, streaming,
         drugstores, homeImprovement, online,
         entertainment, utilities, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dining: return "Dining"
        case .travel: return "Travel"
        case .groceries: return "Groceries"
        case .gas: return "Gas"
        case .streaming: return "Streaming"
        case .drugstores: return "Drugstores"
        case .homeImprovement: return "Home Improvement"
        case .online: return "Online Shopping"
        case .entertainment: return "Entertainment"
        case .utilities: return "Utilities"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .travel: return "airplane"
        case .groceries: return "cart.fill"
        case .gas: return "fuelpump.fill"
        case .streaming: return "play.tv.fill"
        case .drugstores: return "cross.case.fill"
        case .homeImprovement: return "hammer.fill"
        case .online: return "globe"
        case .entertainment: return "ticket.fill"
        case .utilities: return "bolt.fill"
        case .other: return "creditcard.fill"
        }
    }
}

struct ChurnRuleRef: Codable, Hashable {
    let issuerRules: [String]
    let cardSpecificRules: [CardRule]
}

struct CardRule: Codable, Hashable {
    let cardId: String
    let rule: String
    let effectiveDate: Date?
}
