import Foundation
#if DEBUG
import os

/// Spike test infrastructure: simulates sudden bursts of activity
/// such as iCloud restore, first launch, and bulk imports.
class SpikeTestHelper {
    private static let logger = Logger(subsystem: Constants.bundleID, category: "SpikeTest")

    struct SpikeTestResult {
        let scenario: String
        let timeToUsableState: TimeInterval
        let peakMemoryMB: Int
        let itemsProcessed: Int
        let errors: [String]

        var summary: String {
            """
            === Spike: \(scenario) ===
            Time to usable: \(String(format: "%.2f", timeToUsableState))s
            Peak Memory: \(peakMemoryMB) MB
            Items Processed: \(itemsProcessed)
            Errors: \(errors.count)
            """
        }
    }

    // MARK: - Scenario 1: First Launch / iCloud Restore

    /// Simulates first-launch-like scenario by clearing local cache
    /// and measuring time to restore data from CloudKit.
    static func simulateFirstLaunch(
        feedService: DataFeedService,
        cardViewModel: CardViewModel
    ) async -> SpikeTestResult {
        let start = Date()
        var errors: [String] = []
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        logger.info("🚀 Spike test: Simulating first launch...")

        // Clear local caches (but preserve actual data backup)
        let backupKey = "spikeTest_backup_userCards"
        let originalData = UserDefaults.standard.data(forKey: "localUserCards")
        UserDefaults.standard.set(originalData, forKey: backupKey)

        // Clear feed cache
        UserDefaults.standard.removeObject(forKey: Constants.feedCacheKey)
        UserDefaults.standard.removeObject(forKey: Constants.lastSyncKey)

        // Reload everything from scratch
        feedService.loadData()
        cardViewModel.loadCards()

        let loadTime = Date().timeIntervalSince(start)

        // Validate data loaded correctly
        if feedService.cards.isEmpty {
            errors.append("Card catalog empty after reload")
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used

        // Restore backup
        if let backup = UserDefaults.standard.data(forKey: backupKey) {
            UserDefaults.standard.set(backup, forKey: "localUserCards")
        }
        UserDefaults.standard.removeObject(forKey: backupKey)

        // Reload original data
        cardViewModel.loadCards()

        logger.info("🚀 Spike test: First launch complete in \(String(format: "%.2f", loadTime))s")

        return SpikeTestResult(
            scenario: "First Launch Simulation",
            timeToUsableState: loadTime,
            peakMemoryMB: max(peakMem, startMem),
            itemsProcessed: feedService.cards.count + cardViewModel.userCards.count,
            errors: errors
        )
    }

    // MARK: - Scenario 2: Bulk Card Import

    /// Simulates importing many cards at once, like restoring from a backup.
    static func simulateBulkImport(
        cardViewModel: CardViewModel,
        count: Int = 25
    ) async -> SpikeTestResult {
        let start = Date()
        var errors: [String] = []
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        logger.info("🚀 Spike test: Bulk importing \(count) cards...")

        let stressCards = StressTestHelper.generateStressTestCards(count: count)
        let originalCount = cardViewModel.userCards.count

        // Rapid-fire card additions
        for card in stressCards {
            cardViewModel.addCard(card)
        }

        let importTime = Date().timeIntervalSince(start)

        // Validate
        let expectedCount = originalCount + count
        if cardViewModel.userCards.count != expectedCount {
            errors.append("Expected \(expectedCount) cards, got \(cardViewModel.userCards.count)")
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used

        // Clean up stress cards
        for card in stressCards {
            cardViewModel.deleteCard(card)
        }

        logger.info("🚀 Spike test: Bulk import complete in \(String(format: "%.2f", importTime))s")

        return SpikeTestResult(
            scenario: "Bulk Import (\(count) cards)",
            timeToUsableState: importTime,
            peakMemoryMB: max(peakMem, startMem),
            itemsProcessed: count,
            errors: errors
        )
    }

    // MARK: - Scenario 3: Rapid Tab Switching

    /// Simulates rapid navigation changes that might cause view lifecycle issues.
    /// This doesn't actually switch tabs but exercises the data paths.
    static func simulateRapidDataAccess(
        feedService: DataFeedService,
        cardViewModel: CardViewModel,
        iterations: Int = 50
    ) async -> SpikeTestResult {
        let start = Date()
        var errors: [String] = []
        var processed = 0
        let startMem = MemoryMonitor.shared.getMemoryUsage().used

        logger.info("🚀 Spike test: Rapid data access (\(iterations) iterations)...")

        for i in 0..<iterations {
            // Simulate wallet tab access
            let _ = cardViewModel.filteredCards
            let _ = cardViewModel.cardsWithActiveBonus
            let _ = cardViewModel.totalAnnualCards24Months

            // Simulate churn tracker access
            let churnService = ChurnEligibilityService()
            let _ = churnService.calculate524Status(
                userCards: cardViewModel.userCards,
                feedService: feedService
            )
            let _ = churnService.issuerStatuses(
                userCards: cardViewModel.userCards,
                churnRules: feedService.churnRules
            )

            // Simulate transfer partner access
            let _ = feedService.transferPartners.filter { $0.type == .airline }
            let _ = feedService.transferPartners.filter { $0.type == .hotel }
            let _ = feedService.transferRoutes

            // Simulate offers access
            let _ = feedService.offers

            processed += 1

            // Very short delay to simulate animation frames
            if i % 5 == 0 {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~1 frame at 60fps
            }
        }

        let peakMem = MemoryMonitor.shared.getMemoryUsage().used
        let duration = Date().timeIntervalSince(start)

        if processed != iterations {
            errors.append("Only completed \(processed)/\(iterations) iterations")
        }

        logger.info("🚀 Spike test: Rapid access complete in \(String(format: "%.2f", duration))s")

        return SpikeTestResult(
            scenario: "Rapid Data Access (\(iterations)x)",
            timeToUsableState: duration,
            peakMemoryMB: max(peakMem, startMem),
            itemsProcessed: processed,
            errors: errors
        )
    }

    // MARK: - Run All

    static func runAllTests(
        feedService: DataFeedService,
        cardViewModel: CardViewModel
    ) async -> [SpikeTestResult] {
        var results: [SpikeTestResult] = []

        let firstLaunch = await simulateFirstLaunch(
            feedService: feedService,
            cardViewModel: cardViewModel
        )
        results.append(firstLaunch)

        let bulkImport = await simulateBulkImport(
            cardViewModel: cardViewModel
        )
        results.append(bulkImport)

        let rapidAccess = await simulateRapidDataAccess(
            feedService: feedService,
            cardViewModel: cardViewModel
        )
        results.append(rapidAccess)

        return results
    }
}
#endif
