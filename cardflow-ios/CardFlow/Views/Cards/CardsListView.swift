import SwiftUI

struct CardsListView: View {
    @Environment(DataStore.self) private var store
    @State private var showAddCard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.cards) { card in
                        NavigationLink(destination: CardDetailView(card: card)) {
                            CardRow(card: card, holders: store.holders)
                        }
                    }
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("All Cards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddCard = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ColorTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView()
            }
        }
    }
}

struct CardRow: View {
    let card: CreditCard
    let holders: [String]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(card.issuer) \(card.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.textPrimary)
                        .lineLimit(1)

                    let colors = ColorTheme.holderColor(for: card.holder, in: holders)
                    Text(card.holder)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(colors.text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colors.bg)
                        .cornerRadius(8)
                }

                Text("Opened \(Formatters.formatDate(card.openDate)) • APR \(String(format: "%.2f", card.apr))%")
                    .font(.caption)
                    .foregroundColor(ColorTheme.textMuted)

                // Signup bonus progress
                if let bonus = card.signupBonus, !bonus.completed {
                    let progress = min(bonus.current / bonus.target, 1.0)
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(ColorTheme.gold)
                        Text("\(Formatters.formatCurrency(bonus.current)) / \(Formatters.formatCurrency(bonus.target))")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.goldLight)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if card.currentBalance > 0 {
                    Text(Formatters.formatCurrency(card.currentBalance))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.red)
                }
                if card.annualFee > 0 {
                    Text("\(Formatters.formatCurrency(card.annualFee))/yr")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.border, lineWidth: 1))
    }
}
