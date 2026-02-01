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
        lastModified: Date = Date()
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
