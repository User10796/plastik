import Foundation

// MARK: - Churn Rule Types

enum ChurnRuleType: String, Codable, Hashable {
    case applicationEligibility
    case bonusEligibility

    var displayName: String {
        switch self {
        case .applicationEligibility: return "Application"
        case .bonusEligibility: return "Bonus"
        }
    }

    var icon: String {
        switch self {
        case .applicationEligibility: return "person.badge.shield.checkmark"
        case .bonusEligibility: return "gift"
        }
    }
}

enum ChurnRuleCategory: String, Codable, Hashable {
    case velocityLimit
    case productFamily
    case bonusCooldown
    case lifetimeLanguage
    case existingRelationship
    case maxCards
    case cooldownPeriod

    var displayName: String {
        switch self {
        case .velocityLimit: return "Velocity Limit"
        case .productFamily: return "Product Family"
        case .bonusCooldown: return "Bonus Cooldown"
        case .lifetimeLanguage: return "Lifetime Language"
        case .existingRelationship: return "Existing Relationship"
        case .maxCards: return "Max Cards"
        case .cooldownPeriod: return "Cooldown Period"
        }
    }

    var icon: String {
        switch self {
        case .velocityLimit: return "speedometer"
        case .productFamily: return "rectangle.stack"
        case .bonusCooldown: return "clock.arrow.circlepath"
        case .lifetimeLanguage: return "exclamationmark.triangle"
        case .existingRelationship: return "building.columns"
        case .maxCards: return "rectangle.stack.badge.plus"
        case .cooldownPeriod: return "timer"
        }
    }
}

enum CooldownStartPoint: String, Codable, Hashable {
    case bonusReceived
    case cardClosed
    case cardOpened
}

// MARK: - Churn Rule Model

struct ChurnRule: Codable, Identifiable, Hashable {
    let id: String
    let issuer: Issuer
    let ruleType: ChurnRuleType
    let category: ChurnRuleCategory
    let name: String
    let description: String
    let details: String

    // Velocity limits
    let windowMonths: Int?
    let maxCards: Int?
    let countsAllIssuers: Bool?
    let businessExempt: Bool?

    // Bonus eligibility
    let requiresNotCurrentlyHolding: Bool?
    let cooldownMonths: Int?
    let cooldownStartsFrom: CooldownStartPoint?

    // Product family rules
    let conflictingProducts: [String]?
    let productFamily: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        issuer = try container.decode(Issuer.self, forKey: .issuer)
        ruleType = try container.decode(ChurnRuleType.self, forKey: .ruleType)
        category = try container.decode(ChurnRuleCategory.self, forKey: .category)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        details = try container.decode(String.self, forKey: .details)
        windowMonths = try container.decodeIfPresent(Int.self, forKey: .windowMonths)
        maxCards = try container.decodeIfPresent(Int.self, forKey: .maxCards)
        countsAllIssuers = try container.decodeIfPresent(Bool.self, forKey: .countsAllIssuers)
        businessExempt = try container.decodeIfPresent(Bool.self, forKey: .businessExempt)
        requiresNotCurrentlyHolding = try container.decodeIfPresent(Bool.self, forKey: .requiresNotCurrentlyHolding)
        cooldownMonths = try container.decodeIfPresent(Int.self, forKey: .cooldownMonths)
        cooldownStartsFrom = try container.decodeIfPresent(CooldownStartPoint.self, forKey: .cooldownStartsFrom)
        conflictingProducts = try container.decodeIfPresent([String].self, forKey: .conflictingProducts)
        productFamily = try container.decodeIfPresent(String.self, forKey: .productFamily)
    }
}

// Note: ChurnRuleRef and CardRule are defined in CreditCard.swift
