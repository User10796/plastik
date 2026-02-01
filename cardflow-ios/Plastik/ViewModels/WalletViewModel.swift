import Foundation

@Observable
class WalletViewModel {
    var selectedCategory: SpendCategory = .dining

    func bestCard(
        for category: SpendCategory,
        userCards: [UserCard],
        catalog: [CreditCard]
    ) -> (userCard: UserCard, creditCard: CreditCard, rate: Double)? {
        let activeCards = userCards.filter { $0.isActive }

        var best: (UserCard, CreditCard, Double)?

        for userCard in activeCards {
            guard let creditCard = catalog.first(where: { $0.id == userCard.cardId }) else { continue }
            let rate = creditCard.earningRates.first { $0.category == category }?.multiplier
                ?? creditCard.earningRates.first { $0.category == .other }?.multiplier
                ?? 1.0

            if let current = best {
                if rate > current.2 {
                    best = (userCard, creditCard, rate)
                }
            } else {
                best = (userCard, creditCard, rate)
            }
        }

        return best
    }

    func topCards(
        for category: SpendCategory,
        userCards: [UserCard],
        catalog: [CreditCard],
        limit: Int = 3
    ) -> [(userCard: UserCard, creditCard: CreditCard, rate: Double)] {
        let activeCards = userCards.filter { $0.isActive }

        let ranked: [(UserCard, CreditCard, Double)] = activeCards.compactMap { userCard in
            guard let creditCard = catalog.first(where: { $0.id == userCard.cardId }) else { return nil }
            let rate = creditCard.earningRates.first { $0.category == category }?.multiplier
                ?? creditCard.earningRates.first { $0.category == .other }?.multiplier
                ?? 1.0
            return (userCard, creditCard, rate)
        }
        .sorted { $0.2 > $1.2 }

        return Array(ranked.prefix(limit))
    }
}
