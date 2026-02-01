import Foundation
import SwiftUI

// MARK: - Retention Recommendation

enum RetentionRecommendation: String, Codable, CaseIterable {
    case keep
    case cancel
    case downgrade
    case callRetention
    case waitForBonus

    var displayText: String {
        switch self {
        case .keep: return "Keep"
        case .cancel: return "Cancel"
        case .downgrade: return "Downgrade"
        case .callRetention: return "Call Retention"
        case .waitForBonus: return "Wait for Bonus"
        }
    }

    var color: Color {
        switch self {
        case .keep: return .green
        case .cancel: return .red
        case .downgrade: return .orange
        case .callRetention: return .yellow
        case .waitForBonus: return .blue
        }
    }
}

// MARK: - Retention Action

enum RetentionAction: String, Codable {
    case productChange
    case cancel
    case keep
    case requestRetentionOffer
}

// MARK: - Retention Alternative

struct RetentionAlternative: Identifiable, Codable {
    let id: String
    let action: RetentionAction
    let targetCard: String?
    let benefit: String
    let considerations: [String]

    init(id: String = UUID().uuidString, action: RetentionAction, targetCard: String? = nil, benefit: String, considerations: [String]) {
        self.id = id
        self.action = action
        self.targetCard = targetCard
        self.benefit = benefit
        self.considerations = considerations
    }
}

// MARK: - Rechurn Analysis

struct RechurnAnalysis: Codable {
    let canRechurn: Bool
    let bonusEligibleDate: Date?
    let historicalBonusRange: String
    let recommendation: String
}

// MARK: - Card Retention Analysis

struct CardRetentionAnalysis: Identifiable {
    let id: String
    let userCard: UserCard
    let card: CreditCard
    let annualFee: Int
    let totalBenefitValue: Int
    let netValue: Int
    let recommendation: RetentionRecommendation
    let reasoning: String
    let alternatives: [RetentionAlternative]
    let rechurnAnalysis: RechurnAnalysis?
}
