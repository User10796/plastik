import Foundation

@Observable
class CardViewModel {
    var userCards: [UserCard] = []
    var searchText = ""
    var selectedIssuerFilter: Issuer?

    // Sync status
    var isSyncing = false
    var lastSyncError: String?
    var lastSyncDate: Date?

    private let cloudKit = CloudKitService()
    private let localStorageKey = "localUserCards"

    // Shared App Group for widget access
    private var sharedDefaults: UserDefaults? {
        Constants.sharedDefaults
    }

    var filteredCards: [UserCard] {
        var result = userCards
        if selectedIssuerFilter != nil {
            // Issuer filtering requires access to card catalog - handled in view layer
        }
        if !searchText.isEmpty {
            result = result.filter { card in
                card.cardId.localizedCaseInsensitiveContains(searchText) ||
                (card.nickname?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return result.sorted { $0.openDate > $1.openDate }
    }

    // Active cards (not closed)
    var activeCards: [UserCard] {
        userCards.filter { $0.closedDate == nil }
    }

    // Closed cards
    var closedCards: [UserCard] {
        userCards.filter { $0.closedDate != nil }
    }

    var cardsWithActiveBonus: [UserCard] {
        activeCards.filter { card in
            guard let bonus = card.signupBonusProgress else { return false }
            return !bonus.completed && !bonus.isExpired
        }
    }

    var totalAnnualCards24Months: Int {
        let cutoff = Calendar.current.date(byAdding: .month, value: -24, to: Date()) ?? Date()
        return userCards.filter { $0.openDate > cutoff }.count
    }

    // 5/24 count (only active cards opened in last 24 months)
    var fiveOverTwentyFourCount: Int {
        let cutoff = Calendar.current.date(byAdding: .month, value: -24, to: Date()) ?? Date()
        return activeCards.filter { $0.openDate > cutoff }.count
    }

    // MARK: - Data Operations

    func loadCards() {
        loadFromLocal()
        Task {
            await syncFromCloud()
        }
    }

    /// Manual sync - call this to force a CloudKit refresh
    func manualSync() async {
        await syncFromCloud()
    }

    func addCard(_ card: UserCard) {
        userCards.append(card)
        saveToLocal()
        Task {
            try? await cloudKit.saveUserCard(card)
        }
    }

    func updateCard(_ card: UserCard) {
        if let index = userCards.firstIndex(where: { $0.id == card.id }) {
            var updated = card
            updated.lastModified = Date()
            userCards[index] = updated
            saveToLocal()
            Task {
                try? await cloudKit.saveUserCard(updated)
            }
        }
    }

    func deleteCard(_ card: UserCard) {
        userCards.removeAll { $0.id == card.id }
        saveToLocal()
        Task {
            try? await cloudKit.deleteUserCard(card)
        }
    }

    func updateBonusSpend(for cardId: UUID, amount: Int) {
        guard let index = userCards.firstIndex(where: { $0.id == cardId }),
              var bonus = userCards[index].signupBonusProgress else { return }
        bonus.spentSoFar = amount
        if bonus.spentSoFar >= bonus.targetSpend {
            bonus.completed = true
        }
        userCards[index].signupBonusProgress = bonus
        userCards[index].lastModified = Date()
        saveToLocal()
    }

    // MARK: - Persistence

    private func saveToLocal() {
        guard let data = try? JSONEncoder().encode(userCards) else { return }

        // Save to both standard and shared defaults for widget access
        UserDefaults.standard.set(data, forKey: localStorageKey)
        sharedDefaults?.set(data, forKey: localStorageKey)

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadFromLocal() {
        // Use standard defaults as primary (always available)
        // Shared defaults only used when app group is properly provisioned
        let data = UserDefaults.standard.data(forKey: localStorageKey)

        if let data = data,
           let cards = try? JSONDecoder().decode([UserCard].self, from: data) {
            self.userCards = cards
        }
    }

    private func syncFromCloud() async {
        await MainActor.run { isSyncing = true; lastSyncError = nil }

        do {
            // Ensure zone exists first
            try await cloudKit.setupZone()
            print("CloudKit: Zone setup complete")

            let cloudCards = try await cloudKit.fetchUserCards()
            await MainActor.run {
                mergeCards(cloudCards)
                lastSyncDate = Date()
                isSyncing = false
                print("CloudKit sync: Loaded \(cloudCards.count) cards from cloud")
            }
        } catch {
            let errorMessage = error.localizedDescription
            print("CloudKit sync error: \(errorMessage)")
            await MainActor.run {
                lastSyncError = errorMessage
                isSyncing = false
            }
        }
    }

    private func mergeCards(_ cloudCards: [UserCard]) {
        // Match by cardId + openDate to detect duplicates (handles UUID mismatches)
        var merged: [UserCard] = []
        var seenKeys = Set<String>()
        var localOnlyCards: [UserCard] = []
        var newerLocalCards: [UserCard] = []

        // Helper to create a unique key for deduplication
        func cardKey(_ card: UserCard) -> String {
            let dateStr = ISO8601DateFormatter().string(from: card.openDate)
            return "\(card.cardId)|\(dateStr)"
        }

        // Build lookup of cloud cards
        var cloudCardsByKey: [String: UserCard] = [:]
        for cloudCard in cloudCards {
            cloudCardsByKey[cardKey(cloudCard)] = cloudCard
        }

        // Process all cards - keep the one with newer lastModified
        for cloudCard in cloudCards {
            let key = cardKey(cloudCard)
            if !seenKeys.contains(key) {
                // Check if local version is newer
                if let localCard = userCards.first(where: { cardKey($0) == key }) {
                    if localCard.lastModified > cloudCard.lastModified {
                        // Local is newer - use local and sync to cloud
                        var updatedLocal = localCard
                        updatedLocal.ckRecordID = cloudCard.ckRecordID // Keep the cloud record ID
                        merged.append(updatedLocal)
                        newerLocalCards.append(updatedLocal)
                    } else {
                        // Cloud is newer or same - use cloud
                        merged.append(cloudCard)
                    }
                } else {
                    merged.append(cloudCard)
                }
                seenKeys.insert(key)
            }
        }

        // Add local cards that aren't in cloud (need to push these up)
        for localCard in userCards {
            let key = cardKey(localCard)
            if !seenKeys.contains(key) {
                merged.append(localCard)
                seenKeys.insert(key)
                localOnlyCards.append(localCard)
            }
        }

        userCards = merged
        saveToLocal()

        // Push local-only cards and newer local cards to CloudKit
        let cardsToUpload = localOnlyCards + newerLocalCards
        if !cardsToUpload.isEmpty {
            print("CloudKit: Uploading \(cardsToUpload.count) cards to cloud")
            Task {
                for card in cardsToUpload {
                    do {
                        try await cloudKit.saveUserCard(card)
                        print("CloudKit: Uploaded \(card.cardId)")
                    } catch {
                        print("CloudKit: Failed to upload \(card.cardId): \(error)")
                    }
                }
            }
        }
    }
}

// Import WidgetKit for reloading timelines
import WidgetKit
