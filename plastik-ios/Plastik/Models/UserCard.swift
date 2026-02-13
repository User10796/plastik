import Foundation

struct UserCard: Identifiable, Codable, Hashable {
    static func == (lhs: UserCard, rhs: UserCard) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: UUID
    let cardId: String
    var nickname: String?
    var lastFourDigits: String?
    var openDate: Date
    var annualFeeDate: Date?
    var signupBonusProgress: BonusProgress?
    var benefitUsage: [BenefitUsage]
    var isActive: Bool
    var notes: String?

    // Churn tracking fields
    var closedDate: Date?
    var signupBonusReceivedDate: Date?
    var productFamily: String?
    var isBusinessCard: Bool
    var wasProductChanged: Bool
    var productChangedFrom: String?

    var ckRecordID: String?
    var lastModified: Date

    /// Sort order for manual card ordering (nil = use openDate for default sort)
    var sortOrder: Int?

    /// Date the card was added to the app (for default newest-first sorting)
    var dateAdded: Date

    // MARK: - User-Editable Overrides
    // These fields allow users to override catalog data when it's incorrect

    /// User-provided issuer override (e.g., if catalog is wrong)
    var issuerOverride: String?

    /// User-provided card product name override
    var productNameOverride: String?

    /// User-provided network override
    var networkOverride: String?

    /// User-provided annual fee override (nil = use catalog value)
    var annualFeeOverride: Int?

    /// User-provided foreign transaction fee percentage (nil = use catalog, 0 = no fee)
    var foreignTransactionFeeOverride: Double?

    /// User-provided signup bonus details
    var signupBonusOverride: SignupBonusOverride?

    /// User-provided reward categories (overrides catalog earning rates)
    var rewardCategoriesOverride: [UserRewardCategory]?

    /// User-chosen card icon color (hex string, e.g. "7B2D8B" for purple)
    var cardIconColor: String?

    /// Card status
    var cardStatus: CardStatus

    // MARK: - Statement Import Data

    /// Most recently imported statement balance
    var currentBalance: Double?

    /// Date of the last imported statement
    var lastStatementDate: Date?

    /// Source file name of the last imported statement
    var lastStatementFileName: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id, cardId, nickname, lastFourDigits, openDate, annualFeeDate
        case signupBonusProgress, benefitUsage, isActive, notes
        case closedDate, signupBonusReceivedDate, productFamily
        case isBusinessCard, wasProductChanged, productChangedFrom
        case ckRecordID, lastModified, sortOrder, dateAdded
        case issuerOverride, productNameOverride, networkOverride
        case annualFeeOverride, foreignTransactionFeeOverride
        case signupBonusOverride, rewardCategoriesOverride, cardIconColor, cardStatus
        case currentBalance, lastStatementDate, lastStatementFileName
    }

    // Custom decoder for backward compatibility with existing data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        cardId = try container.decode(String.self, forKey: .cardId)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        lastFourDigits = try container.decodeIfPresent(String.self, forKey: .lastFourDigits)
        openDate = try container.decode(Date.self, forKey: .openDate)
        annualFeeDate = try container.decodeIfPresent(Date.self, forKey: .annualFeeDate)
        signupBonusProgress = try container.decodeIfPresent(BonusProgress.self, forKey: .signupBonusProgress)
        benefitUsage = try container.decodeIfPresent([BenefitUsage].self, forKey: .benefitUsage) ?? []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        closedDate = try container.decodeIfPresent(Date.self, forKey: .closedDate)
        signupBonusReceivedDate = try container.decodeIfPresent(Date.self, forKey: .signupBonusReceivedDate)
        productFamily = try container.decodeIfPresent(String.self, forKey: .productFamily)
        isBusinessCard = try container.decodeIfPresent(Bool.self, forKey: .isBusinessCard) ?? false
        wasProductChanged = try container.decodeIfPresent(Bool.self, forKey: .wasProductChanged) ?? false
        productChangedFrom = try container.decodeIfPresent(String.self, forKey: .productChangedFrom)
        ckRecordID = try container.decodeIfPresent(String.self, forKey: .ckRecordID)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()

        // Sort order fields - backward compatible
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        // dateAdded defaults to openDate for backward compatibility with existing data
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? (try container.decode(Date.self, forKey: .openDate))

        // New override fields - all optional with nil defaults for backward compatibility
        issuerOverride = try container.decodeIfPresent(String.self, forKey: .issuerOverride)
        productNameOverride = try container.decodeIfPresent(String.self, forKey: .productNameOverride)
        networkOverride = try container.decodeIfPresent(String.self, forKey: .networkOverride)
        annualFeeOverride = try container.decodeIfPresent(Int.self, forKey: .annualFeeOverride)
        foreignTransactionFeeOverride = try container.decodeIfPresent(Double.self, forKey: .foreignTransactionFeeOverride)
        signupBonusOverride = try container.decodeIfPresent(SignupBonusOverride.self, forKey: .signupBonusOverride)
        rewardCategoriesOverride = try container.decodeIfPresent([UserRewardCategory].self, forKey: .rewardCategoriesOverride)
        cardIconColor = try container.decodeIfPresent(String.self, forKey: .cardIconColor)

        // Card status - derive from isActive/closedDate if not present
        if let status = try container.decodeIfPresent(CardStatus.self, forKey: .cardStatus) {
            cardStatus = status
        } else if closedDate != nil {
            cardStatus = .closed
        } else if wasProductChanged {
            cardStatus = .productChanged
        } else {
            cardStatus = isActive ? .active : .closed
        }

        // Statement import data - all optional for backward compatibility
        currentBalance = try container.decodeIfPresent(Double.self, forKey: .currentBalance)
        lastStatementDate = try container.decodeIfPresent(Date.self, forKey: .lastStatementDate)
        lastStatementFileName = try container.decodeIfPresent(String.self, forKey: .lastStatementFileName)
    }

    init(
        id: UUID = UUID(),
        cardId: String,
        nickname: String? = nil,
        lastFourDigits: String? = nil,
        openDate: Date = Date(),
        annualFeeDate: Date? = nil,
        signupBonusProgress: BonusProgress? = nil,
        benefitUsage: [BenefitUsage] = [],
        isActive: Bool = true,
        notes: String? = nil,
        closedDate: Date? = nil,
        signupBonusReceivedDate: Date? = nil,
        productFamily: String? = nil,
        isBusinessCard: Bool = false,
        wasProductChanged: Bool = false,
        productChangedFrom: String? = nil,
        ckRecordID: String? = nil,
        lastModified: Date = Date(),
        sortOrder: Int? = nil,
        dateAdded: Date? = nil,
        issuerOverride: String? = nil,
        productNameOverride: String? = nil,
        networkOverride: String? = nil,
        annualFeeOverride: Int? = nil,
        foreignTransactionFeeOverride: Double? = nil,
        signupBonusOverride: SignupBonusOverride? = nil,
        rewardCategoriesOverride: [UserRewardCategory]? = nil,
        cardIconColor: String? = nil,
        cardStatus: CardStatus = .active,
        currentBalance: Double? = nil,
        lastStatementDate: Date? = nil,
        lastStatementFileName: String? = nil
    ) {
        self.id = id
        self.cardId = cardId
        self.nickname = nickname
        self.lastFourDigits = lastFourDigits
        self.openDate = openDate
        self.annualFeeDate = annualFeeDate
        self.signupBonusProgress = signupBonusProgress
        self.benefitUsage = benefitUsage
        self.isActive = isActive
        self.notes = notes
        self.closedDate = closedDate
        self.signupBonusReceivedDate = signupBonusReceivedDate
        self.productFamily = productFamily
        self.isBusinessCard = isBusinessCard
        self.wasProductChanged = wasProductChanged
        self.productChangedFrom = productChangedFrom
        self.ckRecordID = ckRecordID
        self.lastModified = lastModified
        self.sortOrder = sortOrder
        self.dateAdded = dateAdded ?? Date()  // Default to current time for new cards
        self.issuerOverride = issuerOverride
        self.productNameOverride = productNameOverride
        self.networkOverride = networkOverride
        self.annualFeeOverride = annualFeeOverride
        self.foreignTransactionFeeOverride = foreignTransactionFeeOverride
        self.signupBonusOverride = signupBonusOverride
        self.rewardCategoriesOverride = rewardCategoriesOverride
        self.cardIconColor = cardIconColor
        self.cardStatus = cardStatus
        self.currentBalance = currentBalance
        self.lastStatementDate = lastStatementDate
        self.lastStatementFileName = lastStatementFileName
    }
}

// MARK: - Signup Bonus Override

struct SignupBonusOverride: Codable, Hashable {
    var bonusAmount: Int
    var bonusType: RewardType
    var spendRequirement: Int
    var timeframeDays: Int
    var expirationDate: Date?
    var bonusEarned: BonusEarnedStatus

    init(
        bonusAmount: Int = 0,
        bonusType: RewardType = .points,
        spendRequirement: Int = 0,
        timeframeDays: Int = 90,
        expirationDate: Date? = nil,
        bonusEarned: BonusEarnedStatus = .inProgress
    ) {
        self.bonusAmount = bonusAmount
        self.bonusType = bonusType
        self.spendRequirement = spendRequirement
        self.timeframeDays = timeframeDays
        self.expirationDate = expirationDate
        self.bonusEarned = bonusEarned
    }
}

enum BonusEarnedStatus: String, Codable, CaseIterable {
    case yes = "Yes"
    case no = "No"
    case inProgress = "In Progress"

    var displayName: String { rawValue }
}

enum RewardType: String, Codable, CaseIterable {
    case points = "Points"
    case cashBack = "Cash Back"
    case miles = "Miles"

    var displayName: String { rawValue }

    var perDollarLabel: String {
        switch self {
        case .points: return "points per $1"
        case .cashBack: return "% cash back"
        case .miles: return "miles per $1"
        }
    }
}

// MARK: - User Reward Category

struct UserRewardCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var categoryName: String
    var rewardRate: Double
    var rewardType: RewardType
    var capAmount: Int?
    var capPeriod: CapPeriodType?
    var notes: String?

    init(
        id: UUID = UUID(),
        categoryName: String,
        rewardRate: Double,
        rewardType: RewardType = .points,
        capAmount: Int? = nil,
        capPeriod: CapPeriodType? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.categoryName = categoryName
        self.rewardRate = rewardRate
        self.rewardType = rewardType
        self.capAmount = capAmount
        self.capPeriod = capPeriod
        self.notes = notes
    }

    var formattedRate: String {
        if rewardType == .cashBack {
            return "\(rewardRate.formatted(.number.precision(.fractionLength(0...1))))%"
        } else {
            return "\(rewardRate.formatted(.number.precision(.fractionLength(0...1))))x"
        }
    }

    var formattedCap: String? {
        guard let amount = capAmount, let period = capPeriod else { return nil }
        return "$\(amount.commaFormatted)/\(period.shortName)"
    }
}

enum CapPeriodType: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annual = "Annual"
    case calendarYear = "Calendar Year"

    var displayName: String { rawValue }

    var shortName: String {
        switch self {
        case .monthly: return "month"
        case .quarterly: return "quarter"
        case .annual: return "year"
        case .calendarYear: return "cal year"
        }
    }
}

// MARK: - Card Status

enum CardStatus: String, Codable, CaseIterable {
    case active = "Active"
    case closed = "Closed"
    case productChanged = "Product Changed"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .closed: return "xmark.circle.fill"
        case .productChanged: return "arrow.triangle.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .active: return "green"
        case .closed: return "red"
        case .productChanged: return "orange"
        }
    }
}

struct BonusProgress: Codable {
    var spentSoFar: Int
    var targetSpend: Int
    var deadline: Date
    var completed: Bool

    var progress: Double {
        guard targetSpend > 0 else { return 0 }
        return min(Double(spentSoFar) / Double(targetSpend), 1.0)
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }

    var isExpired: Bool {
        deadline < Date() && !completed
    }
}

struct BenefitUsage: Codable, Identifiable {
    let id: UUID
    let benefitId: String
    var usedAmount: Double
    var resetDate: Date

    init(id: UUID = UUID(), benefitId: String, usedAmount: Double = 0, resetDate: Date) {
        self.id = id
        self.benefitId = benefitId
        self.usedAmount = usedAmount
        self.resetDate = resetDate
    }
}
