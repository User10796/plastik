import SwiftUI

struct CardListView: View {
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var showAddCard = false

    // Separate active and closed cards
    private var activeCards: [UserCard] {
        viewModel.filteredCards.filter { $0.closedDate == nil }
    }

    private var closedCards: [UserCard] {
        viewModel.filteredCards.filter { $0.closedDate != nil }
    }

    var body: some View {
        @Bindable var vm = viewModel

        List {
            // Active Bonuses section
            if !viewModel.cardsWithActiveBonus.isEmpty {
                Section("Active Bonuses") {
                    ForEach(viewModel.cardsWithActiveBonus) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            BonusProgressRow(userCard: userCard, card: card)
                        }
                    }
                }
            }

            // Active Cards section
            Section("Active Cards (\(activeCards.count))") {
                if activeCards.isEmpty {
                    ContentUnavailableView(
                        "No Active Cards",
                        systemImage: "creditcard",
                        description: Text("Add a card to get started tracking your rewards.")
                    )
                } else {
                    ForEach(activeCards) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            CardRow(userCard: userCard, card: card)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                closeCard(userCard)
                            } label: {
                                Label("Close", systemImage: "xmark.circle")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete(perform: deleteActiveCards)
                }
            }

            // Closed Cards section
            if !closedCards.isEmpty {
                Section("Closed Cards (\(closedCards.count))") {
                    ForEach(closedCards) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            ClosedCardRow(userCard: userCard, card: card)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                reopenCard(userCard)
                            } label: {
                                Label("Reopen", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.green)
                        }
                    }
                    .onDelete(perform: deleteClosedCards)
                }
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

    private func closeCard(_ userCard: UserCard) {
        var updated = userCard
        updated.closedDate = Date()
        viewModel.updateCard(updated)
    }

    private func reopenCard(_ userCard: UserCard) {
        var updated = userCard
        updated.closedDate = nil
        viewModel.updateCard(updated)
    }

    private func deleteActiveCards(at offsets: IndexSet) {
        for index in offsets {
            let card = activeCards[index]
            viewModel.deleteCard(card)
        }
    }

    private func deleteClosedCards(at offsets: IndexSet) {
        for index in offsets {
            let card = closedCards[index]
            viewModel.deleteCard(card)
        }
    }
}

struct CardRow: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(card.map { issuerColor($0.issuer) } ?? .gray)
                .frame(width: 44, height: 28)
                .overlay {
                    Text(card?.network.displayName.prefix(1) ?? "?")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(userCard.nickname ?? card?.name ?? userCard.cardId)
                    .font(.headline)
                Text(card?.issuer.displayName ?? "Unknown Issuer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let fee = card?.annualFee, fee > 0 {
                    Text(fee.currencyFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if card != nil {
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

struct ClosedCardRow: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 44, height: 28)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(userCard.nickname ?? card?.name ?? userCard.cardId)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(card?.issuer.displayName ?? "Unknown Issuer")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if let closedDate = userCard.closedDate {
                        Text("• Closed \(closedDate.shortFormatted)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Show rechurn eligibility if available
            if let closedDate = userCard.closedDate {
                let monthsSinceClosed = Calendar.current.dateComponents([.month], from: closedDate, to: Date()).month ?? 0
                if monthsSinceClosed >= 48 {
                    Text("Rechurn Ready")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("\(48 - monthsSinceClosed)mo")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct BonusProgressRow: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(userCard.nickname ?? card?.name ?? userCard.cardId)
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
