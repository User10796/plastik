import Foundation

// MARK: - Eligibility Result Types

struct ChurnEligibility {
    let canApply: Bool
    let canGetBonus: Bool
    let applicationBlockers: [ChurnBlocker]
    let bonusBlockers: [ChurnBlocker]
    let nextEligibleDate: Date?
    let recommendations: [String]
}

struct ChurnBlocker: Identifiable {
    let id = UUID()
    let rule: ChurnRule
    let reason: String
    let resolveDate: Date?
    let actionRequired: String?
}

struct CardIn524: Identifiable {
    let id: UUID
    let card: UserCard
    let cardName: String
    let agesOutDate: Date

    var daysUntilAgeOut: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: agesOutDate).day ?? 0
    }
}

struct UpcomingSlot: Identifiable {
    let id = UUID()
    let date: Date
    let newCount: Int
    let cardAgingOut: UserCard
    let cardName: String
}

// MARK: - Issuer Eligibility Summary

struct IssuerEligibilityStatus: Identifiable {
    let id: String
    let issuer: Issuer
    let canApply: Bool
    let status: EligibilityLevel
    let summary: String
    let nextEligibleDate: Date?

    enum EligibilityLevel {
        case safe, caution, blocked
    }
}

// MARK: - Bonus Timeline Item

struct BonusTimelineItem: Identifiable {
    let id: String
    let cardName: String
    let issuer: Issuer
    let eligibleDate: Date?
    let status: BonusStatus
    let detail: String

    enum BonusStatus {
        case eligible, cooldown, lifetime, unknown
    }
}

// MARK: - Service

@Observable
class ChurnEligibilityService {

    func checkEligibility(
        for card: CreditCard,
        userCards: [UserCard],
        churnRules: [ChurnRule]
    ) -> ChurnEligibility {
        let issuerRules = churnRules.filter { $0.issuer == card.issuer }
        var applicationBlockers: [ChurnBlocker] = []
        var bonusBlockers: [ChurnBlocker] = []
        var recommendations: [String] = []

        for rule in issuerRules {
            switch rule.ruleType {
            case .applicationEligibility:
                if let blocker = checkApplicationRule(rule, card: card, userCards: userCards) {
                    applicationBlockers.append(blocker)
                }
            case .bonusEligibility:
                if let blocker = checkBonusRule(rule, card: card, userCards: userCards) {
                    bonusBlockers.append(blocker)
                }
            }
        }

        let canApply = applicationBlockers.isEmpty
        let canGetBonus = bonusBlockers.isEmpty

        // Generate recommendations
        if !canApply {
            let soonest = applicationBlockers.compactMap(\.resolveDate).min()
            if let date = soonest {
                recommendations.append("Wait until \(date.shortFormatted) to apply")
            }
            for blocker in applicationBlockers {
                if let action = blocker.actionRequired {
                    recommendations.append(action)
                }
            }
        } else if canApply && !canGetBonus {
            recommendations.append("You can get approved but won't receive the signup bonus")
            let soonest = bonusBlockers.compactMap(\.resolveDate).min()
            if let date = soonest {
                recommendations.append("Bonus eligible after \(date.shortFormatted)")
            }
        } else {
            recommendations.append("You're eligible for both the card and the bonus!")
        }

        let nextDate = (applicationBlockers + bonusBlockers).compactMap(\.resolveDate).min()

        return ChurnEligibility(
            canApply: canApply,
            canGetBonus: canGetBonus,
            applicationBlockers: applicationBlockers,
            bonusBlockers: bonusBlockers,
            nextEligibleDate: nextDate,
            recommendations: recommendations
        )
    }

    // MARK: - 5/24 Calculation

    func calculate524Status(userCards: [UserCard], feedService: DataFeedService) -> (count: Int, details: [CardIn524]) {
        let cutoff = Calendar.current.date(byAdding: .month, value: -24, to: Date()) ?? Date()

        let cardsIn524 = userCards
            .filter { $0.openDate > cutoff && !$0.isBusinessCard }
            .compactMap { userCard -> CardIn524? in
                let name = feedService.card(for: userCard.cardId)?.name ?? userCard.nickname ?? "Unknown"
                guard let agesOut = Calendar.current.date(byAdding: .month, value: 24, to: userCard.openDate) else { return nil }
                return CardIn524(id: userCard.id, card: userCard, cardName: name, agesOutDate: agesOut)
            }
            .sorted { $0.agesOutDate < $1.agesOutDate }

        return (cardsIn524.count, cardsIn524)
    }

    func getUpcomingSlots(userCards: [UserCard], feedService: DataFeedService) -> [UpcomingSlot] {
        let (currentCount, details) = calculate524Status(userCards: userCards, feedService: feedService)
        var slots: [UpcomingSlot] = []
        var count = currentCount

        for card in details where card.agesOutDate > Date() {
            count -= 1
            let name = feedService.card(for: card.card.cardId)?.name ?? card.cardName
            slots.append(UpcomingSlot(date: card.agesOutDate, newCount: count, cardAgingOut: card.card, cardName: name))
        }

        return slots
    }

    // MARK: - Issuer Status

    func issuerStatuses(userCards: [UserCard], churnRules: [ChurnRule]) -> [IssuerEligibilityStatus] {
        let issuers = Set(churnRules.map(\.issuer))
        return issuers.sorted { $0.displayName < $1.displayName }.map { issuer in
            let rules = churnRules.filter { $0.issuer == issuer && $0.ruleType == .applicationEligibility }
            var blocked = false
            var caution = false
            var summary = "Safe to apply"
            let nextDate: Date? = nil

            for rule in rules {
                switch rule.category {
                case .velocityLimit:
                    if let window = rule.windowMonths, let max = rule.maxCards {
                        let cutoff = Calendar.current.date(byAdding: .month, value: -window, to: Date()) ?? Date()
                        let count: Int
                        if rule.countsAllIssuers == true {
                            count = userCards.filter { $0.openDate > cutoff && !(rule.businessExempt == true && $0.isBusinessCard) }.count
                        } else {
                            // Issuer-specific count would need card catalog lookup
                            count = 0
                        }
                        if count >= max {
                            blocked = true
                            summary = "Over \(max)/\(window) limit"
                        } else if count >= max - 1 {
                            caution = true
                            summary = "Last slot (\(count)/\(max))"
                        }
                    }
                case .maxCards:
                    if let max = rule.maxCards {
                        let openCards = userCards.filter { $0.closedDate == nil }
                        if openCards.count >= max {
                            blocked = true
                            summary = "At max \(max) cards"
                        }
                    }
                case .existingRelationship:
                    caution = true
                    summary = "Existing relationship recommended"
                default:
                    break
                }
            }

            let level: IssuerEligibilityStatus.EligibilityLevel
            if blocked { level = .blocked }
            else if caution { level = .caution }
            else { level = .safe }

            return IssuerEligibilityStatus(
                id: issuer.rawValue,
                issuer: issuer,
                canApply: !blocked,
                status: level,
                summary: summary,
                nextEligibleDate: nextDate
            )
        }
    }

    // MARK: - Private Helpers

    private func checkApplicationRule(_ rule: ChurnRule, card: CreditCard, userCards: [UserCard]) -> ChurnBlocker? {
        switch rule.category {
        case .velocityLimit:
            guard let windowMonths = rule.windowMonths, let maxCards = rule.maxCards else { return nil }
            let cutoff = Calendar.current.date(byAdding: .month, value: -windowMonths, to: Date()) ?? Date()
            let count: Int
            if rule.countsAllIssuers == true {
                count = userCards.filter { $0.openDate > cutoff && !(rule.businessExempt == true && $0.isBusinessCard) }.count
            } else {
                count = userCards.filter { $0.openDate > cutoff }.count
            }
            if count >= maxCards {
                let oldest = userCards.filter { $0.openDate > cutoff }.sorted { $0.openDate < $1.openDate }.first
                let resolveDate = oldest.flatMap { Calendar.current.date(byAdding: .month, value: windowMonths, to: $0.openDate) }
                return ChurnBlocker(rule: rule, reason: "You have \(count) cards in \(windowMonths) months (limit: \(maxCards))", resolveDate: resolveDate, actionRequired: nil)
            }

        case .productFamily:
            guard let conflicting = rule.conflictingProducts else { return nil }
            let hasConflicting = userCards.filter { $0.closedDate == nil }.contains { conflicting.contains($0.cardId) }
            if hasConflicting {
                return ChurnBlocker(rule: rule, reason: "You currently hold a \(rule.productFamily ?? "conflicting") product", resolveDate: nil, actionRequired: "Cancel or product change your existing \(rule.productFamily ?? "") card first")
            }

        case .maxCards:
            guard let max = rule.maxCards else { return nil }
            let openCards = userCards.filter { $0.closedDate == nil }
            if openCards.count >= max {
                return ChurnBlocker(rule: rule, reason: "You have \(openCards.count) open cards (limit: \(max))", resolveDate: nil, actionRequired: "Close an existing card before applying")
            }

        case .existingRelationship:
            return ChurnBlocker(rule: rule, reason: rule.description, resolveDate: nil, actionRequired: "Open a bank account first for better approval odds")

        default:
            break
        }
        return nil
    }

    private func checkBonusRule(_ rule: ChurnRule, card: CreditCard, userCards: [UserCard]) -> ChurnBlocker? {
        switch rule.category {
        case .bonusCooldown:
            guard let cooldownMonths = rule.cooldownMonths else { return nil }
            let family = rule.productFamily
            let relevantCards = userCards.filter { uc in
                if let fam = family { return uc.productFamily == fam }
                return uc.cardId == card.id
            }

            for uc in relevantCards {
                let startDate: Date?
                switch rule.cooldownStartsFrom {
                case .bonusReceived: startDate = uc.signupBonusReceivedDate
                case .cardClosed: startDate = uc.closedDate
                case .cardOpened: startDate = uc.openDate
                case .none: startDate = uc.openDate
                }

                if let start = startDate {
                    guard let eligibleDate = Calendar.current.date(byAdding: .month, value: cooldownMonths, to: start) else { continue }
                    if eligibleDate > Date() {
                        return ChurnBlocker(rule: rule, reason: "\(cooldownMonths)-month cooldown from \(rule.cooldownStartsFrom?.rawValue ?? "open")", resolveDate: eligibleDate, actionRequired: nil)
                    }
                }
            }

            if rule.requiresNotCurrentlyHolding == true {
                let hasCard = userCards.contains { $0.cardId == card.id && $0.closedDate == nil }
                if hasCard {
                    return ChurnBlocker(rule: rule, reason: "Must not currently hold this card", resolveDate: nil, actionRequired: "Cancel the card first, then wait for cooldown")
                }
            }

        case .lifetimeLanguage:
            let everHad = userCards.contains { $0.cardId == card.id || $0.productChangedFrom == card.id }
            if everHad {
                return ChurnBlocker(rule: rule, reason: "Once per lifetime: you have previously held this card", resolveDate: nil, actionRequired: "Look for targeted bypass offers")
            }

        default:
            break
        }
        return nil
    }
}
