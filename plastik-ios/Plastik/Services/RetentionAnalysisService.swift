import Foundation

@Observable
class RetentionAnalysisService {

    func analyzeCard(userCard: UserCard, card: CreditCard, feedService: DataFeedService) -> CardRetentionAnalysis {
        let annualFee = card.annualFee
        let totalBenefitValue = calculateBenefitValue(card: card, userCard: userCard)
        let netValue = totalBenefitValue - annualFee

        let rechurnAnalysis = buildRechurnAnalysis(userCard: userCard, card: card, feedService: feedService)
        let downgradePath = feedService.downgradePaths(for: card.id)
        let recommendation = determineRecommendation(
            netValue: netValue,
            rechurnAnalysis: rechurnAnalysis,
            hasDowngradePath: downgradePath != nil
        )
        let reasoning = buildReasoning(
            netValue: netValue,
            annualFee: annualFee,
            totalBenefitValue: totalBenefitValue,
            recommendation: recommendation,
            rechurnAnalysis: rechurnAnalysis
        )
        let alternatives = buildAlternatives(
            card: card,
            downgradePath: downgradePath,
            rechurnAnalysis: rechurnAnalysis,
            recommendation: recommendation
        )

        return CardRetentionAnalysis(
            id: userCard.id.uuidString,
            userCard: userCard,
            card: card,
            annualFee: annualFee,
            totalBenefitValue: totalBenefitValue,
            netValue: netValue,
            recommendation: recommendation,
            reasoning: reasoning,
            alternatives: alternatives,
            rechurnAnalysis: rechurnAnalysis
        )
    }

    // MARK: - Benefit Calculation

    private func calculateBenefitValue(card: CreditCard, userCard: UserCard) -> Int {
        var total = 0.0
        for benefit in card.benefits {
            let usage = userCard.benefitUsage.first { $0.benefitId == benefit.id }
            let used = usage?.usedAmount ?? 0
            // Count the lesser of benefit value or actual usage toward total value
            let effectiveValue = min(benefit.value, used > 0 ? used : benefit.value)
            total += effectiveValue
        }
        return Int(total)
    }

    // MARK: - Recommendation Logic

    private func determineRecommendation(
        netValue: Int,
        rechurnAnalysis: RechurnAnalysis?,
        hasDowngradePath: Bool
    ) -> RetentionRecommendation {
        // Net positive by $50+ -> keep
        if netValue >= 50 {
            return .keep
        }

        // Borderline (-$50 to +$50) -> call retention
        if netValue >= -50 && netValue < 50 {
            return .callRetention
        }

        // Net negative but close to rechurn -> wait for bonus
        if let rechurn = rechurnAnalysis, rechurn.canRechurn {
            if let eligibleDate = rechurn.bonusEligibleDate {
                let monthsUntilEligible = eligibleDate.monthsFrom(Date())
                if monthsUntilEligible <= 6 {
                    return .waitForBonus
                }
            } else {
                return .waitForBonus
            }
        }

        // Net negative, has downgrade path -> downgrade
        if hasDowngradePath {
            return .downgrade
        }

        // Net negative, no downgrade, not rechurnable -> cancel
        return .cancel
    }

    // MARK: - Rechurn Analysis

    private func buildRechurnAnalysis(userCard: UserCard, card: CreditCard, feedService: DataFeedService) -> RechurnAnalysis? {
        let historicalBonus = feedService.historicalBonus(for: card.id)
        let churnRules = feedService.rules(for: card)
        let bonusRules = churnRules.filter { $0.ruleType == .bonusEligibility }

        // Check if card has lifetime language (not rechurnable)
        let hasLifetimeLanguage = bonusRules.contains { $0.category == .lifetimeLanguage }
        if hasLifetimeLanguage {
            return RechurnAnalysis(
                canRechurn: false,
                bonusEligibleDate: nil,
                historicalBonusRange: historicalBonus?.typicalRange ?? "N/A",
                recommendation: "This card has lifetime language - bonus is once per lifetime."
            )
        }

        // Find cooldown-based eligibility
        var bonusEligibleDate: Date?
        for rule in bonusRules where rule.category == .bonusCooldown {
            guard let cooldownMonths = rule.cooldownMonths else { continue }

            let startDate: Date?
            switch rule.cooldownStartsFrom {
            case .bonusReceived: startDate = userCard.signupBonusReceivedDate
            case .cardClosed: startDate = userCard.closedDate
            case .cardOpened: startDate = userCard.openDate
            case .none: startDate = userCard.openDate
            }

            if let start = startDate,
               let eligible = Calendar.current.date(byAdding: .month, value: cooldownMonths, to: start) {
                if let existing = bonusEligibleDate {
                    if eligible > existing { bonusEligibleDate = eligible }
                } else {
                    bonusEligibleDate = eligible
                }
            }
        }

        let canRechurn = bonusEligibleDate != nil || (!hasLifetimeLanguage && !bonusRules.isEmpty)
        let historicalRange = historicalBonus?.typicalRange ?? "Unknown"
        let recommendation = historicalBonus?.recommendation ?? buildDefaultRechurnRecommendation(canRechurn: canRechurn, eligibleDate: bonusEligibleDate)

        return RechurnAnalysis(
            canRechurn: canRechurn,
            bonusEligibleDate: bonusEligibleDate,
            historicalBonusRange: historicalRange,
            recommendation: recommendation
        )
    }

    private func buildDefaultRechurnRecommendation(canRechurn: Bool, eligibleDate: Date?) -> String {
        if !canRechurn {
            return "This card is not eligible for rechurning."
        }
        if let date = eligibleDate {
            if date <= Date() {
                return "You are currently eligible for a new signup bonus."
            }
            return "You will be eligible for a new bonus after \(date.shortFormatted)."
        }
        return "Check issuer rules for bonus eligibility timing."
    }

    // MARK: - Reasoning

    private func buildReasoning(
        netValue: Int,
        annualFee: Int,
        totalBenefitValue: Int,
        recommendation: RetentionRecommendation,
        rechurnAnalysis: RechurnAnalysis?
    ) -> String {
        var parts: [String] = []

        parts.append("Annual fee: \(annualFee.currencyFormatted). Estimated benefit value: \(totalBenefitValue.currencyFormatted). Net value: \(netValue.currencyFormatted).")

        switch recommendation {
        case .keep:
            parts.append("This card provides strong net positive value and is worth keeping.")
        case .cancel:
            parts.append("This card costs more than the value you receive from its benefits, with no downgrade path available.")
        case .downgrade:
            parts.append("This card costs more than you receive in benefits, but a no-fee or lower-fee downgrade is available to preserve your credit history.")
        case .callRetention:
            parts.append("The value is borderline. Call the retention line to request a retention offer (statement credit or bonus points) before deciding.")
        case .waitForBonus:
            if let rechurn = rechurnAnalysis, let date = rechurn.bonusEligibleDate {
                parts.append("While the card is net negative, you will be eligible for a new signup bonus after \(date.shortFormatted). Consider keeping until then.")
            } else {
                parts.append("A rechurn opportunity may be available soon. Hold the card until you can capture a new signup bonus.")
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Alternatives

    private func buildAlternatives(
        card: CreditCard,
        downgradePath: DowngradePath?,
        rechurnAnalysis: RechurnAnalysis?,
        recommendation: RetentionRecommendation
    ) -> [RetentionAlternative] {
        var alternatives: [RetentionAlternative] = []

        // Always offer retention call as an alternative unless already recommended
        if recommendation != .callRetention {
            alternatives.append(RetentionAlternative(
                action: .requestRetentionOffer,
                targetCard: nil,
                benefit: "Request a retention offer (statement credit or bonus points) to offset the annual fee",
                considerations: [
                    "Call the number on the back of your card",
                    "Mention you are considering canceling due to the annual fee",
                    "Be prepared to accept or decline their offer on the spot"
                ]
            ))
        }

        // Downgrade options
        if let paths = downgradePath {
            for option in paths.toCards {
                alternatives.append(RetentionAlternative(
                    action: .productChange,
                    targetCard: option.cardId,
                    benefit: "Product change to \(option.cardId) to keep your credit line and history",
                    considerations: option.considerations
                ))
            }
        }

        // Cancel option
        if recommendation != .cancel {
            var cancelConsiderations = [
                "Your credit line will be closed, which may affect your credit utilization ratio",
                "You will lose any remaining benefits immediately"
            ]
            if let rechurn = rechurnAnalysis, rechurn.canRechurn {
                cancelConsiderations.append("After canceling, you may be eligible for a new signup bonus (\(rechurn.historicalBonusRange))")
            }
            alternatives.append(RetentionAlternative(
                action: .cancel,
                targetCard: nil,
                benefit: "Cancel the card to stop paying the annual fee",
                considerations: cancelConsiderations
            ))
        }

        // Keep option
        if recommendation != .keep {
            alternatives.append(RetentionAlternative(
                action: .keep,
                targetCard: nil,
                benefit: "Keep the card and maximize benefit usage to offset the fee",
                considerations: [
                    "Review all available benefits and set reminders to use them",
                    "Consider whether upcoming travel or purchases change the value calculation"
                ]
            ))
        }

        return alternatives
    }
}
