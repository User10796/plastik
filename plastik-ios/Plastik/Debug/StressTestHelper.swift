import Foundation
#if DEBUG

/// Stress test infrastructure: generates synthetic load to find performance
/// limits and identify bottlenecks under heavy usage.
class StressTestHelper {

    struct StressTestResult {
        let scenario: String
        let duration: TimeInterval
        let operationsCompleted: Int
        let peakMemoryMB: Int
        let errors: [String]
        let passed: Bool

        var summary: String {
            """
            === \(scenario) ===
            Duration: \(String(format: "%.2f", duration))s
            Operations: \(operationsCompleted)
            Peak Memory: \(peakMemoryMB) MB
            Errors: \(errors.count)
            Result: \(passed ? "✅ PASS" : "❌ FAIL")
            """
        }
    }

    // MARK: - Scenario 1: Many Cards

    /// Generates a large number of synthetic user cards to test UI performance
    /// with heavy data loads. Default 50 cards spans various issuers and dates.
    static func generateStressTestCards(count: Int = 50) -> [UserCard] {
        let cardIds = [
            "chase-sapphire-preferred", "chase-sapphire-reserve",
            "chase-freedom-flex", "chase-freedom-unlimited",
            "amex-gold", "amex-platinum", "amex-green",
            "citi-premier", "citi-double-cash",
            "capital-one-venture-x", "capital-one-venture"
        ]
        let families: [String?] = ["Sapphire", "Freedom", nil, "Platinum", nil]

        return (0..<count).map { i in
            let randomDaysAgo = Double.random(in: 0...730) * 86400
            let openDate = Date().addingTimeInterval(-randomDaysAgo)
            let isBusiness = i % 7 == 0
            let isClosed = i % 10 == 0

            return UserCard(
                id: UUID(),
                cardId: cardIds[i % cardIds.count],
                nickname: "Stress Card \(i)",
                openDate: openDate,
                annualFeeDate: Calendar.current.date(byAdding: .year, value: 1, to: openDate),
                isActive: !isClosed,
                closedDate: isClosed ? Date().addingTimeInterval(-Double.random(in: 0...180) * 86400) : nil,
                signupBonusReceivedDate: Bool.random() ? openDate.addingTimeInterval(90 * 86400) : nil,
                productFamily: families[i % families.count],
                isBusinessCard: isBusiness
            )
        }
    }

    // MARK: - Scenario 2: Rapid Eligibility Calculations

    /// Runs many rapid eligibility calculations to stress the ChurnEligibilityService.
    static func runRapidEligibilityChecks(
        feedService: DataFeedService,
        userCards: [UserCard],
        iterations: Int = 100
    ) async -> StressTestResult {
        let start = Date()
        let service = ChurnEligibilityService()
        var errors: [String] = []
        var completed = 0
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        for i in 0..<iterations {
            // Check 5/24 status
            let status = service.calculate524Status(userCards: userCards, feedService: feedService)
            if status.count < 0 {
                errors.append("Invalid 5/24 count at iteration \(i)")
            }

            // Check eligibility for each card in catalog
            for card in feedService.cards.prefix(5) {
                let rules = feedService.rules(for: card)
                let eligibility = service.checkEligibility(for: card, userCards: userCards, churnRules: rules)
                // Validate result consistency
                if eligibility.canApply && !eligibility.applicationBlockers.isEmpty {
                    errors.append("Inconsistent: canApply=true but has blockers at iter \(i)")
                }
            }

            // Get issuer statuses
            _ = service.issuerStatuses(userCards: userCards, churnRules: feedService.churnRules)

            // Get upcoming slots
            _ = service.getUpcomingSlots(userCards: userCards, feedService: feedService)

            completed += 1

            // Yield to prevent blocking UI
            if i % 10 == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used
        let duration = Date().timeIntervalSince(start)

        return StressTestResult(
            scenario: "Rapid Eligibility Checks (\(iterations)x)",
            duration: duration,
            operationsCompleted: completed,
            peakMemoryMB: max(peakMem, startMem),
            errors: errors,
            passed: errors.isEmpty && duration < Double(iterations) * 0.1
        )
    }

    // MARK: - Scenario 3: Data Feed Parsing

    /// Repeatedly parses the card data feed to stress JSON decoding.
    static func runDataFeedStressTest(iterations: Int = 50) async -> StressTestResult {
        let start = Date()
        var errors: [String] = []
        var completed = 0
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        for i in 0..<iterations {
            let service = DataFeedService()
            service.loadData()

            if service.cards.isEmpty {
                errors.append("Empty card catalog at iteration \(i)")
            }
            if service.churnRules.isEmpty {
                errors.append("Empty churn rules at iteration \(i)")
            }

            completed += 1

            if i % 10 == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used
        let duration = Date().timeIntervalSince(start)

        return StressTestResult(
            scenario: "Data Feed Parsing (\(iterations)x)",
            duration: duration,
            operationsCompleted: completed,
            peakMemoryMB: max(peakMem, startMem),
            errors: errors,
            passed: errors.isEmpty
        )
    }

    // MARK: - Scenario 4: Retention Analysis

    /// Runs retention analysis across many cards to test the service.
    static func runRetentionAnalysisStress(
        feedService: DataFeedService,
        userCards: [UserCard],
        iterations: Int = 50
    ) async -> StressTestResult {
        let start = Date()
        let service = RetentionAnalysisService()
        var errors: [String] = []
        var completed = 0
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        for i in 0..<iterations {
            for userCard in userCards.prefix(10) {
                if let card = feedService.card(for: userCard.cardId) {
                    let analysis = service.analyzeCard(
                        userCard: userCard,
                        card: card,
                        feedService: feedService
                    )
                    // Validate analysis
                    if analysis.annualFee < 0 {
                        errors.append("Invalid annual fee at iteration \(i)")
                    }
                }
            }
            completed += 1

            if i % 10 == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used
        let duration = Date().timeIntervalSince(start)

        return StressTestResult(
            scenario: "Retention Analysis (\(iterations)x)",
            duration: duration,
            operationsCompleted: completed,
            peakMemoryMB: max(peakMem, startMem),
            errors: errors,
            passed: errors.isEmpty
        )
    }

    // MARK: - Run All

    /// Runs all stress test scenarios sequentially and returns combined results.
    static func runAllTests(
        feedService: DataFeedService,
        cardViewModel: CardViewModel
    ) async -> [StressTestResult] {
        var results: [StressTestResult] = []

        // Generate stress cards
        let stressCards = generateStressTestCards(count: 50)
        let allCards = cardViewModel.userCards + stressCards

        // Run each scenario
        let eligibilityResult = await runRapidEligibilityChecks(
            feedService: feedService,
            userCards: allCards
        )
        results.append(eligibilityResult)

        let feedResult = await runDataFeedStressTest()
        results.append(feedResult)

        let retentionResult = await runRetentionAnalysisStress(
            feedService: feedService,
            userCards: allCards
        )
        results.append(retentionResult)

        return results
    }
}
#endif
