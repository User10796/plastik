import Foundation

// MARK: - SignupBonus

struct SignupBonus: Codable, Identifiable {
    var id: String { "\(target)-\(rewardType)-\(reward)" }

    var target: Double
    var current: Double
    var reward: Double
    var rewardType: String
    var deadline: String?
    var completed: Bool

    enum CodingKeys: String, CodingKey {
        case target
        case current
        case reward
        case rewardType
        case deadline
        case completed
    }

    init(
        target: Double = 0,
        current: Double = 0,
        reward: Double = 0,
        rewardType: String = "points",
        deadline: String? = nil,
        completed: Bool = false
    ) {
        self.target = target
        self.current = current
        self.reward = reward
        self.rewardType = rewardType
        self.deadline = deadline
        self.completed = completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decodeIfPresent(Double.self, forKey: .target) ?? 0
        current = try container.decodeIfPresent(Double.self, forKey: .current) ?? 0
        reward = try container.decodeIfPresent(Double.self, forKey: .reward) ?? 0
        rewardType = try container.decodeIfPresent(String.self, forKey: .rewardType) ?? "points"
        deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
    }
}

// MARK: - SpendingCap

struct SpendingCap: Codable, Identifiable {
    var id: String { "\(category)-\(rate)-\(cap)" }

    var category: String
    var rate: Double
    var cap: Double
    var currentSpend: Double
    var resetDate: String

    enum CodingKeys: String, CodingKey {
        case category
        case rate
        case cap
        case currentSpend
        case resetDate
    }

    init(
        category: String = "",
        rate: Double = 0,
        cap: Double = 0,
        currentSpend: Double = 0,
        resetDate: String = ""
    ) {
        self.category = category
        self.rate = rate
        self.cap = cap
        self.currentSpend = currentSpend
        self.resetDate = resetDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        rate = try container.decodeIfPresent(Double.self, forKey: .rate) ?? 0
        cap = try container.decodeIfPresent(Double.self, forKey: .cap) ?? 0
        currentSpend = try container.decodeIfPresent(Double.self, forKey: .currentSpend) ?? 0
        resetDate = try container.decodeIfPresent(String.self, forKey: .resetDate) ?? ""
    }
}

// MARK: - CreditCard

struct CreditCard: Codable, Identifiable {
    var id: Int
    var name: String
    var issuer: String
    var holder: String
    var annualFee: Double
    var apr: Double
    var currentBalance: Double
    var creditLimit: Double
    var openDate: String
    var anniversaryDate: String
    var signupBonus: SignupBonus?
    var spendingCaps: [SpendingCap]
    var churnEligible: String?
    var pointsType: String?
    var notes: String
    var feeDecision: String?
    var retentionOffer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case issuer
        case holder
        case annualFee
        case apr
        case currentBalance
        case creditLimit
        case openDate
        case anniversaryDate
        case signupBonus
        case spendingCaps
        case churnEligible
        case pointsType
        case notes
        case feeDecision
        case retentionOffer
    }

    init(
        id: Int = Int(Date().timeIntervalSince1970 * 1000),
        name: String = "",
        issuer: String = "",
        holder: String = "",
        annualFee: Double = 0,
        apr: Double = 0,
        currentBalance: Double = 0,
        creditLimit: Double = 0,
        openDate: String = "",
        anniversaryDate: String = "",
        signupBonus: SignupBonus? = nil,
        spendingCaps: [SpendingCap] = [],
        churnEligible: String? = nil,
        pointsType: String? = nil,
        notes: String = "",
        feeDecision: String? = nil,
        retentionOffer: String? = nil
    ) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.holder = holder
        self.annualFee = annualFee
        self.apr = apr
        self.currentBalance = currentBalance
        self.creditLimit = creditLimit
        self.openDate = openDate
        self.anniversaryDate = anniversaryDate
        self.signupBonus = signupBonus
        self.spendingCaps = spendingCaps
        self.churnEligible = churnEligible
        self.pointsType = pointsType
        self.notes = notes
        self.feeDecision = feeDecision
        self.retentionOffer = retentionOffer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? Int(Date().timeIntervalSince1970 * 1000)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        issuer = try container.decodeIfPresent(String.self, forKey: .issuer) ?? ""
        holder = try container.decodeIfPresent(String.self, forKey: .holder) ?? ""
        annualFee = try container.decodeIfPresent(Double.self, forKey: .annualFee) ?? 0
        apr = try container.decodeIfPresent(Double.self, forKey: .apr) ?? 0
        currentBalance = try container.decodeIfPresent(Double.self, forKey: .currentBalance) ?? 0
        creditLimit = try container.decodeIfPresent(Double.self, forKey: .creditLimit) ?? 0
        openDate = try container.decodeIfPresent(String.self, forKey: .openDate) ?? ""
        anniversaryDate = try container.decodeIfPresent(String.self, forKey: .anniversaryDate) ?? ""
        signupBonus = try container.decodeIfPresent(SignupBonus.self, forKey: .signupBonus)
        spendingCaps = try container.decodeIfPresent([SpendingCap].self, forKey: .spendingCaps) ?? []
        churnEligible = try container.decodeIfPresent(String.self, forKey: .churnEligible)
        pointsType = try container.decodeIfPresent(String.self, forKey: .pointsType)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        feeDecision = try container.decodeIfPresent(String.self, forKey: .feeDecision)
        retentionOffer = try container.decodeIfPresent(String.self, forKey: .retentionOffer)
    }
}
