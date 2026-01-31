import Foundation

struct CardApplication: Codable, Identifiable {
    var id: Int
    var cardName: String
    var issuer: String
    var holder: String
    var applicationDate: String
    var approvalDate: String?
    var status: String
    var signupBonus: Double
    var signupSpend: Double
    var bonusDeadline: String?
    var creditLimit: Double
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case cardName
        case issuer
        case holder
        case applicationDate
        case approvalDate
        case status
        case signupBonus
        case signupSpend
        case bonusDeadline
        case creditLimit
        case notes
    }

    init(
        id: Int = Int(Date().timeIntervalSince1970 * 1000),
        cardName: String = "",
        issuer: String = "",
        holder: String = "",
        applicationDate: String = "",
        approvalDate: String? = nil,
        status: String = "Pending",
        signupBonus: Double = 0,
        signupSpend: Double = 0,
        bonusDeadline: String? = nil,
        creditLimit: Double = 0,
        notes: String = ""
    ) {
        self.id = id
        self.cardName = cardName
        self.issuer = issuer
        self.holder = holder
        self.applicationDate = applicationDate
        self.approvalDate = approvalDate
        self.status = status
        self.signupBonus = signupBonus
        self.signupSpend = signupSpend
        self.bonusDeadline = bonusDeadline
        self.creditLimit = creditLimit
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? Int(Date().timeIntervalSince1970 * 1000)
        cardName = try container.decodeIfPresent(String.self, forKey: .cardName) ?? ""
        issuer = try container.decodeIfPresent(String.self, forKey: .issuer) ?? ""
        holder = try container.decodeIfPresent(String.self, forKey: .holder) ?? ""
        applicationDate = try container.decodeIfPresent(String.self, forKey: .applicationDate) ?? ""
        approvalDate = try container.decodeIfPresent(String.self, forKey: .approvalDate)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "Pending"
        signupBonus = try container.decodeIfPresent(Double.self, forKey: .signupBonus) ?? 0
        signupSpend = try container.decodeIfPresent(Double.self, forKey: .signupSpend) ?? 0
        bonusDeadline = try container.decodeIfPresent(String.self, forKey: .bonusDeadline)
        creditLimit = try container.decodeIfPresent(Double.self, forKey: .creditLimit) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
