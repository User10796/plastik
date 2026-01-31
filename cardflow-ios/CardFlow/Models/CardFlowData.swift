import Foundation

struct CardFlowData: Codable {
    var schemaVersion: Int
    var lastModified: String
    var lastModifiedBy: String
    var cards: [CreditCard]
    var pointsBalances: [String: Double]
    var companionPasses: [CompanionPass]
    var applications: [CardApplication]
    var creditPulls: [CreditPull]
    var holders: [String]

    init(
        schemaVersion: Int = 1,
        lastModified: String = ISO8601DateFormatter().string(from: Date()),
        lastModifiedBy: String = "ios",
        cards: [CreditCard] = [],
        pointsBalances: [String: Double] = [:],
        companionPasses: [CompanionPass] = [],
        applications: [CardApplication] = [],
        creditPulls: [CreditPull] = [],
        holders: [String] = []
    ) {
        self.schemaVersion = schemaVersion
        self.lastModified = lastModified
        self.lastModifiedBy = lastModifiedBy
        self.cards = cards
        self.pointsBalances = pointsBalances
        self.companionPasses = companionPasses
        self.applications = applications
        self.creditPulls = creditPulls
        self.holders = holders
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case lastModified
        case lastModifiedBy
        case cards
        case pointsBalances
        case companionPasses
        case applications
        case creditPulls
        case holders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        lastModified = try container.decodeIfPresent(String.self, forKey: .lastModified) ?? ISO8601DateFormatter().string(from: Date())
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy) ?? "ios"
        cards = try container.decodeIfPresent([CreditCard].self, forKey: .cards) ?? []
        pointsBalances = try container.decodeIfPresent([String: Double].self, forKey: .pointsBalances) ?? [:]
        companionPasses = try container.decodeIfPresent([CompanionPass].self, forKey: .companionPasses) ?? []
        applications = try container.decodeIfPresent([CardApplication].self, forKey: .applications) ?? []
        creditPulls = try container.decodeIfPresent([CreditPull].self, forKey: .creditPulls) ?? []
        holders = try container.decodeIfPresent([String].self, forKey: .holders) ?? []
    }
}
