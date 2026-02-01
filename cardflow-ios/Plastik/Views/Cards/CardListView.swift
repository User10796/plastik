import SwiftUI

struct CardListView: View {
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var showAddCard = false

    var body: some View {
        @Bindable var vm = viewModel

        List {
            if !viewModel.cardsWithActiveBonus.isEmpty {
                Section("Active Bonuses") {
                    ForEach(viewModel.cardsWithActiveBonus) { userCard in
                        if let card = feedService.card(for: userCard.cardId) {
                            NavigationLink(value: userCard) {
                                BonusProgressRow(userCard: userCard, card: card)
                            }
                        }
                    }
                }
            }

            Section("My Cards") {
                ForEach(viewModel.filteredCards) { userCard in
                    if let card = feedService.card(for: userCard.cardId) {
                        NavigationLink(value: userCard) {
                            CardRow(userCard: userCard, card: card)
                        }
                    }
                }
                .onDelete(perform: deleteCards)
            }

            if viewModel.filteredCards.isEmpty {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "creditcard",
                    description: Text("Add a card to get started tracking your rewards.")
                )
            }
        }
        .searchable(text: $vm.searchText, prompt: "Search cards")
        .navigationTitle("Cards")
        .navigationDestination(for: UserCard.self) { userCard in
            CardDetailView(userCard: userCard)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardView()
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = viewModel.filteredCards[index]
            viewModel.deleteCard(card)
        }
    }
}

struct CardRow: View {
    let userCard: UserCard
    let card: CreditCard

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(issuerColor(card.issuer))
                .frame(width: 44, height: 28)
                .overlay {
                    Text(card.network.displayName.prefix(1))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(userCard.nickname ?? card.name)
                    .font(.headline)
                Text(card.issuer.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if card.annualFee > 0 {
                    Text(card.annualFee.currencyFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No AF")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if let last4 = userCard.lastFourDigits {
                    Text("•••• \(last4)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct BonusProgressRow: View {
    let userCard: UserCard
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(userCard.nickname ?? card.name)
                    .font(.headline)
                Spacer()
                if let bonus = userCard.signupBonusProgress {
                    Text("\(bonus.daysRemaining)d left")
                        .font(.caption)
                        .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
                }
            }

            if let bonus = userCard.signupBonusProgress {
                ProgressView(value: bonus.progress)
                    .tint(bonus.progress >= 1.0 ? .green : .blue)

                HStack {
                    Text("$\(bonus.spentSoFar) / $\(bonus.targetSpend)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(bonus.progress * 100))%")
                        .font(.caption.bold())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private func issuerColor(_ issuer: Issuer) -> Color {
    switch issuer {
    case .chase: return .blue
    case .amex: return .indigo
    case .citi: return .cyan
    case .capitalOne: return .red
    case .barclays: return .teal
    case .usBank: return .purple
    case .wellsFargo: return .orange
    case .bankOfAmerica: return .red.opacity(0.8)
    case .discover: return .orange.opacity(0.8)
    }
}

#Preview {
    NavigationStack {
        CardListView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
