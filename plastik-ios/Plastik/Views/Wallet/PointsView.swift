import SwiftUI

struct PointsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        List {
            Section("Points Summary") {
                ForEach(pointsCurrencies, id: \.name) { currency in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.name)
                                .font(.headline)
                            Text(currency.issuer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(currency.points.commaFormatted)")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }

            if pointsCurrencies.isEmpty {
                ContentUnavailableView(
                    "No Points Yet",
                    systemImage: "star.fill",
                    description: Text("Add cards to your wallet to track points.")
                )
            }

            Section("Transfer Partners") {
                NavigationLink {
                    TransferPartnerMapView()
                } label: {
                    HStack {
                        Label("View Transfer Options", systemImage: "arrow.triangle.swap")
                        Spacer()
                        Text("\(feedService.transferPartners.count) partners")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Points")
    }

    private var pointsCurrencies: [(name: String, issuer: String, points: Int)] {
        var currencies: [(name: String, issuer: String, points: Int)] = []

        let userCardIds = Set(cardViewModel.userCards.map { $0.cardId })
        let userCards = feedService.cards.filter { userCardIds.contains($0.id) }

        // Group by issuer/points program
        var chaseUR = 0
        var amexMR = 0
        var citiTYP = 0
        var capitalOneMiles = 0

        for card in userCards {
            switch card.issuer {
            case .chase:
                chaseUR += 50000 // Placeholder
            case .amex:
                amexMR += 75000 // Placeholder
            case .citi:
                citiTYP += 30000 // Placeholder
            case .capitalOne:
                capitalOneMiles += 40000 // Placeholder
            default:
                break
            }
        }

        if chaseUR > 0 {
            currencies.append(("Ultimate Rewards", "Chase", chaseUR))
        }
        if amexMR > 0 {
            currencies.append(("Membership Rewards", "American Express", amexMR))
        }
        if citiTYP > 0 {
            currencies.append(("ThankYou Points", "Citi", citiTYP))
        }
        if capitalOneMiles > 0 {
            currencies.append(("Miles", "Capital One", capitalOneMiles))
        }

        return currencies
    }
}

#Preview {
    NavigationStack {
        PointsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
