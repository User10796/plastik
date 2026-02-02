import Foundation

@Observable
class OffersViewModel {
    var sortBy: OfferSortOption = .value

    enum OfferSortOption: String, CaseIterable {
        case value = "Value"
        case expiration = "Expiration"
        case issuer = "Issuer"
    }

    func sortedOffers(_ offers: [CardOffer], cards: [CreditCard]) -> [CardOffer] {
        let active = offers.filter { !$0.isExpired }
        switch sortBy {
        case .value:
            return active.sorted { ($0.bonusPoints ?? 0) > ($1.bonusPoints ?? 0) }
        case .expiration:
            return active.sorted { a, b in
                let aDate = a.expirationDate ?? Date.distantFuture
                let bDate = b.expirationDate ?? Date.distantFuture
                return aDate < bDate
            }
        case .issuer:
            return active.sorted { a, b in
                let aCard = cards.first { $0.id == a.cardId }
                let bCard = cards.first { $0.id == b.cardId }
                return (aCard?.issuer.displayName ?? "") < (bCard?.issuer.displayName ?? "")
            }
        }
    }
}
