import SwiftUI

struct OptimalCardView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var walletVM = WalletViewModel()

    var body: some View {
        List {
            ForEach(SpendCategory.allCases) { category in
                if let best = walletVM.bestCard(
                    for: category,
                    userCards: cardViewModel.userCards,
                    catalog: feedService.cards
                ) {
                    HStack {
                        Image(systemName: category.icon)
                            .frame(width: 30)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.displayName)
                                .font(.headline)
                            Text(best.userCard.nickname ?? best.creditCard.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(best.rate.multiplierFormatted)
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Optimal Cards")
    }
}
