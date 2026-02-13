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

    // Custom decoder to handle missing optional fields in JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        issuer = try container.decode(Issuer.self, forKey: .issuer)
        network = try container.decode(CardNetwork.self, forKey: .network)
        annualFee = try container.decode(Int.self, forKey: .annualFee)
        signupBonus = try container.decodeIfPresent(SignupBonus.self, forKey: .signupBonus)
        earningRates = try container.decodeIfPresent([EarningRate].self, forKey: .earningRates) ?? []
        benefits = try container.decodeIfPresent([CardBenefit].self, forKey: .benefits) ?? []
        transferPartners = try container.decodeIfPresent([String].self, forKey: .transferPartners) ?? []
        churnRules = try container.decodeIfPresent(ChurnRuleRef.self, forKey: .churnRules) ?? ChurnRuleRef(issuerRules: [], cardSpecificRules: [])
        referralLink = try container.decodeIfPresent(String.self, forKey: .referralLink)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }

    // Standard memberwise initializer for programmatic use
    init(id: String, name: String, issuer: Issuer, network: CardNetwork, annualFee: Int, signupBonus: SignupBonus?, earningRates: [EarningRate], benefits: [CardBenefit], transferPartners: [String], churnRules: ChurnRuleRef, referralLink: String?, imageURL: String?, lastUpdated: Date) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.network = network
        self.annualFee = annualFee
        self.signupBonus = signupBonus
        self.earningRates = earningRates
        self.benefits = benefits
        self.transferPartners = transferPartners
        self.churnRules = churnRules
        self.referralLink = referralLink
        self.imageURL = imageURL
        self.lastUpdated = lastUpdated
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, issuer, network, annualFee, signupBonus, earningRates, benefits, transferPartners, churnRules, referralLink, imageURL, lastUpdated
    }
}

enum Issuer: String, Codable, CaseIterable, Identifiable {
    // Tier 1 — Major Issuers
    case chase
    case amex
    case citi
    case capitalOne
    case bankOfAmerica
    case wellsFargo
    case usBank
    case barclays
    case discover

    // Tier 2 — Mid-Market & Specialty Issuers
    case usaa
    case navyFederal
    case pnc
    case tdBank
    case synchrony
    case breadFinancial
    case goldmanSachs
    case fnbo
    case creditOne
    case upgrade
    case avant

    // Tier 3 — Tech & Fintech Issuers
    case apple
    case brex
    case ramp
    case mercury

    // Special Category
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        // Tier 1
        case .chase: return "Chase"
        case .amex: return "American Express"
        case .citi: return "Citi"
        case .capitalOne: return "Capital One"
        case .bankOfAmerica: return "Bank of America"
        case .wellsFargo: return "Wells Fargo"
        case .usBank: return "U.S. Bank"
        case .barclays: return "Barclays"
        case .discover: return "Discover"
        // Tier 2
        case .usaa: return "USAA"
        case .navyFederal: return "Navy Federal"
        case .pnc: return "PNC Bank"
        case .tdBank: return "TD Bank"
        case .synchrony: return "Synchrony"
        case .breadFinancial: return "Bread Financial"
        case .goldmanSachs: return "Goldman Sachs"
        case .fnbo: return "FNBO"
        case .creditOne: return "Credit One"
        case .upgrade: return "Upgrade"
        case .avant: return "Avant"
        // Tier 3
        case .apple: return "Apple"
        case .brex: return "Brex"
        case .ramp: return "Ramp"
        case .mercury: return "Mercury"
        // Special
        case .custom: return "Custom Card"
        }
    }

    var abbreviation: String {
        switch self {
        case .chase: return "CHASE"
        case .amex: return "AMEX"
        case .citi: return "CITI"
        case .capitalOne: return "CAP1"
        case .bankOfAmerica: return "BOFA"
        case .wellsFargo: return "WF"
        case .usBank: return "USB"
        case .barclays: return "BARC"
        case .discover: return "DISC"
        case .usaa: return "USAA"
        case .navyFederal: return "NFCU"
        case .pnc: return "PNC"
        case .tdBank: return "TD"
        case .synchrony: return "SYNC"
        case .breadFinancial: return "BREAD"
        case .goldmanSachs: return "GS"
        case .fnbo: return "FNBO"
        case .creditOne: return "C1"
        case .upgrade: return "UPG"
        case .avant: return "AVT"
        case .apple: return "APPLE"
        case .brex: return "BREX"
        case .ramp: return "RAMP"
        case .mercury: return "MERC"
        case .custom: return "CUST"
        }
    }

    /// Whether this issuer is a "Custom Card" placeholder
    var isCustom: Bool {
        self == .custom
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
