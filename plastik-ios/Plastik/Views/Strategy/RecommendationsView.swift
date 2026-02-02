import SwiftUI

struct RecommendationsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        List {
            Section("Recommended Next Cards") {
                if recommendations.isEmpty {
                    ContentUnavailableView(
                        "No Recommendations",
                        systemImage: "lightbulb",
                        description: Text("Add more cards to get personalized recommendations.")
                    )
                } else {
                    ForEach(recommendations) { card in
                        RecommendationRow(card: card, reason: reasonFor(card))
                    }
                }
            }

            Section("Category Gaps") {
                ForEach(categoryGaps, id: \.category) { gap in
                    HStack {
                        Image(systemName: gap.category.icon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(gap.category.displayName)
                                .font(.subheadline.bold())
                            Text("Current best: \(gap.currentRate)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("Could earn \(gap.potentialRate)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Optimization Tips") {
                TipRow(
                    icon: "dollarsign.circle",
                    title: "Maximize signup bonuses",
                    detail: "You have 2 cards with active bonuses to complete"
                )

                TipRow(
                    icon: "arrow.triangle.swap",
                    title: "Consolidate transfer partners",
                    detail: "Consider cards that transfer to your most-used airlines"
                )

                TipRow(
                    icon: "calendar",
                    title: "Annual fee optimization",
                    detail: "Review cards before annual fees hit to decide keep/cancel"
                )
            }
        }
        .navigationTitle("Recommendations")
    }

    private var recommendations: [CreditCard] {
        let userCardIds = Set(cardViewModel.userCards.map { $0.cardId })
        return feedService.cards
            .filter { !userCardIds.contains($0.id) }
            .filter { $0.signupBonus != nil }
            .sorted { ($0.signupBonus?.points ?? 0) > ($1.signupBonus?.points ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    private func reasonFor(_ card: CreditCard) -> String {
        if let bonus = card.signupBonus {
            return "Earn \(bonus.points.commaFormatted) \(bonus.currency) after $\(bonus.spendRequired.commaFormatted) spend"
        }
        return "Great earning rates"
    }

    private var categoryGaps: [(category: SpendCategory, currentRate: String, potentialRate: String)] {
        let userCardIds = Set(cardViewModel.userCards.map { $0.cardId })
        let userCards = feedService.cards.filter { userCardIds.contains($0.id) }

        var gaps: [(SpendCategory, String, String)] = []

        for category in [SpendCategory.dining, .groceries, .gas, .travel] {
            let currentBest = userCards.compactMap { card in
                card.earningRates.first { $0.category == category }?.multiplier
            }.max() ?? 1.0

            let potentialBest = feedService.cards.compactMap { card in
                card.earningRates.first { $0.category == category }?.multiplier
            }.max() ?? 1.0

            if potentialBest > currentBest {
                gaps.append((
                    category,
                    currentBest.multiplierFormatted,
                    potentialBest.multiplierFormatted
                ))
            }
        }

        return gaps
    }
}

struct RecommendationRow: View {
    let card: CreditCard
    let reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.name)
                    .font(.subheadline.bold())
                Spacer()
                if card.annualFee > 0 {
                    Text(card.annualFee.currencyFormatted + "/yr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No AF")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(card.issuer.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(reason)
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RecommendationsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
