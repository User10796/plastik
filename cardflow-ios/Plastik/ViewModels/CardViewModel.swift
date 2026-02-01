import Foundation

@Observable
class CardViewModel {
    var userCards: [UserCard] = []
    var searchText = ""
    var selectedIssuerFilter: Issuer?
    var showActiveOnly = true

    private let cloudKit = CloudKitService()
    private var localStorageKey = "localUserCards"

    var filteredCards: [UserCard] {
        var result = userCards
        if showActiveOnly {
            result = result.filter { $0.isActive }
        }
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

    var cardsWithActiveBonus: [UserCard] {
        userCards.filter { card in
            guard let bonus = card.signupBonusProgress else { return false }
            return !bonus.completed && !bonus.isExpired
        }
    }

    var totalAnnualCards24Months: Int {
        let cutoff = Calendar.current.date(byAdding: .month, value: -24, to: Date()) ?? Date()
        return userCards.filter { $0.openDate > cutoff && $0.isActive }.count
    }

    // MARK: - Data Operations

    func loadCards() {
        loadFromLocal()
        Task {
            await syncFromCloud()
        }
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
        if let data = try? JSONEncoder().encode(userCards) {
            UserDefaults.standard.set(data, forKey: localStorageKey)
        }
    }

    private func loadFromLocal() {
        if let data = UserDefaults.standard.data(forKey: localStorageKey),
           let cards = try? JSONDecoder().decode([UserCard].self, from: data) {
            self.userCards = cards
        }
    }

    private func syncFromCloud() async {
        do {
            let cloudCards = try await cloudKit.fetchUserCards()
            await MainActor.run {
                mergeCards(cloudCards)
            }
        } catch {
            // CloudKit not available - continue with local data
        }
    }

    private func mergeCards(_ cloudCards: [UserCard]) {
        var merged = userCards
        for cloudCard in cloudCards {
            if let localIndex = merged.firstIndex(where: { $0.id == cloudCard.id }) {
                let resolved = cloudKit.resolveConflict(local: merged[localIndex], server: cloudCard)
                merged[localIndex] = resolved
            } else {
                merged.append(cloudCard)
            }
        }
        userCards = merged
        saveToLocal()
    }
}
