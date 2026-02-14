import Foundation
import CloudKit

@Observable
class CardViewModel {
    var userCards: [UserCard] = []
    var searchText = ""
    var selectedIssuerFilter: Issuer?

    // Sync status
    var isSyncing = false
    var lastSyncError: String?
    var lastSyncDate: Date?

    // Track last local edit to prevent sync race conditions
    private var lastLocalEditTime: Date?
    private let syncDebounceInterval: TimeInterval = 2.0  // Seconds to wait after local edit before allowing sync

    private let cloudKit = CloudKitService()
    private let localStorageKey = "localUserCards"

    init() {
        // Setup callback for remote CloudKit changes
        cloudKit.onRemoteChange = { [weak self] in
            Task {
                await self?.syncIncrementalChanges()
            }
        }
    }

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
        return sortedCards(result)
    }

    // Active cards (not closed) - sorted by sortOrder or dateAdded
    var activeCards: [UserCard] {
        sortedCards(userCards.filter { $0.closedDate == nil })
    }

    // Closed cards - sorted by closed date descending
    var closedCards: [UserCard] {
        userCards.filter { $0.closedDate != nil }
            .sorted { ($0.closedDate ?? Date.distantPast) > ($1.closedDate ?? Date.distantPast) }
    }

    /// Sort cards by sortOrder (if set) or dateAdded descending (newest first)
    private func sortedCards(_ cards: [UserCard]) -> [UserCard] {
        cards.sorted { card1, card2 in
            // If both have sortOrder, use that
            if let order1 = card1.sortOrder, let order2 = card2.sortOrder {
                return order1 < order2
            }
            // If only one has sortOrder, it comes first
            if card1.sortOrder != nil { return true }
            if card2.sortOrder != nil { return false }
            // Neither has sortOrder - sort by dateAdded descending (newest first)
            return card1.dateAdded > card2.dateAdded
        }
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

    /// Incremental sync - only fetch changes since last sync
    func syncIncrementalChanges() async {
        // Don't overlap syncs
        guard !isSyncing else {
            print("CloudKit: Skipping incremental sync - already syncing")
            return
        }

        // Don't sync immediately after a local edit to prevent race conditions
        if let lastEdit = lastLocalEditTime,
           Date().timeIntervalSince(lastEdit) < syncDebounceInterval {
            print("CloudKit: Skipping sync - recent local edit (\(Date().timeIntervalSince(lastEdit))s ago)")
            return
        }

        await MainActor.run { isSyncing = true; lastSyncError = nil }

        do {
            let (changedCards, deletedIDs) = try await cloudKit.fetchChanges()

            await MainActor.run {
                // Apply deletions
                for deletedID in deletedIDs {
                    if let index = userCards.firstIndex(where: {
                        $0.ckRecordID == deletedID || $0.id.uuidString == deletedID
                    }) {
                        print("CloudKit: Removing deleted card \(userCards[index].cardId)")
                        userCards.remove(at: index)
                    }
                }

                // Apply changes
                for changedCard in changedCards {
                    if let index = userCards.firstIndex(where: {
                        $0.ckRecordID == changedCard.ckRecordID ||
                        $0.id == changedCard.id ||
                        (cardKey($0) == cardKey(changedCard))
                    }) {
                        // Update existing card ONLY if cloud version is strictly newer
                        // Use > not >= to prefer local changes when timestamps are equal
                        if changedCard.lastModified > userCards[index].lastModified {
                            print("CloudKit: Updating card \(changedCard.cardId) from remote (cloud newer)")
                            userCards[index] = changedCard
                        } else {
                            print("CloudKit: Keeping local card \(userCards[index].cardId) (local newer or equal)")
                        }
                    } else {
                        // New card from cloud
                        print("CloudKit: Adding new card \(changedCard.cardId) from remote")
                        userCards.append(changedCard)
                    }
                }

                if !changedCards.isEmpty || !deletedIDs.isEmpty {
                    saveToLocal()
                    print("CloudKit: Incremental sync applied \(changedCards.count) changes, \(deletedIDs.count) deletions")
                } else {
                    print("CloudKit: Incremental sync - no changes")
                }

                lastSyncDate = Date()
                isSyncing = false
            }
        } catch {
            let errorMessage = error.localizedDescription
            print("CloudKit incremental sync error: \(errorMessage)")
            await MainActor.run {
                lastSyncError = errorMessage
                isSyncing = false
            }

            // If incremental sync failed, try full sync
            if let ckError = error as? CKError, ckError.code == .changeTokenExpired {
                print("CloudKit: Change token expired, doing full sync")
                await syncFromCloud()
            }
        }
    }

    /// Helper to create a unique key for deduplication
    private func cardKey(_ card: UserCard) -> String {
        let dateStr = ISO8601DateFormatter().string(from: card.openDate)
        return "\(card.cardId)|\(dateStr)"
    }

    func addCard(_ card: UserCard) {
        userCards.append(card)
        lastLocalEditTime = Date()  // Track when we made local edits
        saveToLocal()
        Task {
            try? await cloudKit.saveUserCard(card)
        }
    }

    func updateCard(_ card: UserCard) {
        var updated = card
        updated.lastModified = Date()

        print("CardViewModel.updateCard: \(card.cardId) id=\(card.id) color=\(card.cardIconColor ?? "nil")")
        print("CardViewModel.updateCard: array has \(userCards.count) cards, IDs: \(userCards.map { "\($0.cardId)(\($0.id.uuidString.prefix(8)))" }.joined(separator: ", "))")

        if let index = userCards.firstIndex(where: { $0.id == card.id }) {
            // Found by UUID - update in place
            let oldColor = userCards[index].cardIconColor
            userCards[index] = updated
            print("CardViewModel: Updated \(card.cardId) by UUID at index \(index), color: \(oldColor ?? "nil") -> \(updated.cardIconColor ?? "nil")")
        } else if let index = userCards.firstIndex(where: { $0.cardId == card.cardId && $0.openDate == card.openDate }) {
            // Fallback: find by cardId + openDate (handles UUID mismatches)
            let oldId = userCards[index].id
            userCards[index] = updated
            print("CardViewModel: Updated \(card.cardId) by cardId+openDate fallback at index \(index) (UUID mismatch: had \(oldId), got \(card.id))")
        } else {
            // Card not found - this shouldn't happen but log it
            print("CardViewModel: WARNING - Card \(card.cardId) NOT FOUND in array, cannot update!")
            print("CardViewModel: Looking for id=\(card.id), cardId=\(card.cardId), openDate=\(card.openDate)")
            print("CardViewModel: Array cardIds: \(userCards.map(\.cardId))")
            return
        }

        lastLocalEditTime = Date()  // Track when we made local edits
        saveToLocal()
        Task {
            try? await cloudKit.saveUserCard(updated)
        }
    }

    func deleteCard(_ card: UserCard) {
        userCards.removeAll { $0.id == card.id }
        saveToLocal()
        Task {
            try? await cloudKit.deleteUserCard(card)
        }
    }

    // MARK: - Card Ordering

    /// Move active cards from source indices to destination index
    func moveActiveCards(from source: IndexSet, to destination: Int) {
        // Get sorted active cards
        var active = activeCards

        // Perform the move
        active.move(fromOffsets: source, toOffset: destination)

        // Update sortOrder for all active cards
        updateSortOrderForCards(active)
    }

    /// Move closed cards from source indices to destination index
    func moveClosedCards(from source: IndexSet, to destination: Int) {
        var closed = closedCards
        closed.move(fromOffsets: source, toOffset: destination)
        updateSortOrderForCards(closed)
    }

    /// Update sortOrder for a list of cards and persist changes
    private func updateSortOrderForCards(_ orderedCards: [UserCard]) {
        var cardsToUpdate: [UserCard] = []

        for (index, card) in orderedCards.enumerated() {
            if let userIndex = userCards.firstIndex(where: { $0.id == card.id }) {
                userCards[userIndex].sortOrder = index
                userCards[userIndex].lastModified = Date()
                cardsToUpdate.append(userCards[userIndex])
            }
        }

        saveToLocal()

        // Sync updated cards to CloudKit
        Task {
            for card in cardsToUpdate {
                try? await cloudKit.saveUserCard(card)
            }
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
        guard let data = try? JSONEncoder().encode(userCards) else {
            print("CardViewModel: Failed to encode userCards")
            return
        }

        // Save to standard defaults
        UserDefaults.standard.set(data, forKey: localStorageKey)
        UserDefaults.standard.synchronize()

        // Save to shared defaults for widget access
        if let shared = sharedDefaults {
            shared.set(data, forKey: localStorageKey)
            shared.synchronize()
            print("CardViewModel: Saved \(userCards.count) cards to shared defaults (\(data.count) bytes)")
        } else {
            print("CardViewModel: WARNING - sharedDefaults is nil, widget won't see updates")
        }

        // Also write to a file in the shared container (more reliable than UserDefaults for widgets)
        if let containerURL = Constants.appGroupContainerURL {
            let fileURL = containerURL.appendingPathComponent("userCards.json")
            do {
                try data.write(to: fileURL, options: .atomic)
                print("CardViewModel: Wrote \(data.count) bytes to shared file \(fileURL.lastPathComponent)")
            } catch {
                print("CardViewModel: Failed to write shared file: \(error)")
            }
        }

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
        print("CardViewModel: Triggered widget timeline reload")
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

        // Build lookup of cloud cards
        var cloudCardsByKey: [String: UserCard] = [:]
        for cloudCard in cloudCards {
            cloudCardsByKey[cardKey(cloudCard)] = cloudCard
        }

        // Process all cards - keep the one with newer lastModified
        for cloudCard in cloudCards {
            let key = cardKey(cloudCard)
            if !seenKeys.contains(key) {
                // Check if local version is newer or equal (prefer local on ties)
                if let localCard = userCards.first(where: { cardKey($0) == key }) {
                    if localCard.lastModified >= cloudCard.lastModified {
                        // Local is newer or same - use local (prefer local to preserve edits)
                        var updatedLocal = localCard
                        updatedLocal.ckRecordID = cloudCard.ckRecordID // Keep the cloud record ID
                        merged.append(updatedLocal)
                        if localCard.lastModified > cloudCard.lastModified {
                            newerLocalCards.append(updatedLocal)
                        }
                    } else {
                        // Cloud is strictly newer - use cloud
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
