import SwiftUI

struct OffersView: View {
    @Environment(DataFeedService.self) private var feedService
    @Environment(CardViewModel.self) private var cardViewModel
    @State private var offersVM = OffersViewModel()
    @State private var searchText = ""
    @State private var selectedIssuerFilter: Issuer?

    private var filteredOffers: [CardOffer] {
        var offers = offersVM.sortedOffers(feedService.offers, cards: feedService.cards)

        if let issuer = selectedIssuerFilter {
            offers = offers.filter { offer in
                feedService.card(for: offer.cardId)?.issuer == issuer
            }
        }

        if !searchText.isEmpty {
            offers = offers.filter { offer in
                offer.title.localizedCaseInsensitiveContains(searchText) ||
                offer.description.localizedCaseInsensitiveContains(searchText) ||
                (feedService.card(for: offer.cardId)?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return offers
    }

    var body: some View {
        List {
            filtersSection

            ForEach(filteredOffers) { offer in
                NavigationLink(value: offer.id) {
                    OfferRow(
                        offer: offer,
                        card: feedService.card(for: offer.cardId),
                        alreadyHasCard: cardViewModel.userCards.contains { $0.cardId == offer.cardId }
                    )
                }
            }

            if filteredOffers.isEmpty {
                ContentUnavailableView(
                    "No Offers",
                    systemImage: "tag",
                    description: Text(searchText.isEmpty ? "No current card offers available." : "No offers match your search.")
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search offers")
        .navigationTitle("Offers")
        .navigationDestination(for: String.self) { offerId in
            if let offer = feedService.offers.first(where: { $0.id == offerId }) {
                OfferDetailView(offer: offer)
            }
        }
    }

    @ViewBuilder
    private var filtersSection: some View {
        Section {
            Picker("Sort by", selection: $offersVM.sortBy) {
                ForEach(OffersViewModel.OfferSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All",
                        isSelected: selectedIssuerFilter == nil,
                        action: { selectedIssuerFilter = nil }
                    )
                    ForEach(availableIssuers, id: \.self) { issuer in
                        FilterChip(
                            label: issuer.displayName,
                            isSelected: selectedIssuerFilter == issuer,
                            action: { selectedIssuerFilter = issuer }
                        )
                    }
                }
            }
        }
    }

    private var availableIssuers: [Issuer] {
        let issuers = Set(feedService.offers.compactMap { feedService.card(for: $0.cardId)?.issuer })
        return Issuer.allCases.filter { issuers.contains($0) }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? AnyShapeStyle(.blue) : AnyShapeStyle(.ultraThinMaterial))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct OfferRow: View {
    let offer: CardOffer
    let card: CreditCard?
    let alreadyHasCard: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(offer.title)
                    .font(.headline)
                Spacer()
                if let points = offer.bonusPoints {
                    Text("\(points.commaFormatted) pts")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }

            if let card {
                HStack(spacing: 4) {
                    Text(card.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if alreadyHasCard {
                        Text("In Wallet")
                            .font(.caption2.bold())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }

            HStack {
                if let spend = offer.spendRequired, let days = offer.timeframeDays {
                    Text("\(spend.currencyFormatted) in \(days) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let card, card.annualFee > 0 {
                    Text("\(card.annualFee.currencyFormatted)/yr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let daysLeft = offer.daysUntilExpiration {
                    Text(daysLeft > 0 ? "\(daysLeft)d left" : "Expired")
                        .font(.caption)
                        .foregroundStyle(daysLeft < 30 ? .red : .secondary)
                }
            }

            if offer.isTargeted {
                Text("Targeted")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 4)
    }
}
