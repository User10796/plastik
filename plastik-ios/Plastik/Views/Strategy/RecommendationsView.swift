import SwiftUI

struct RecommendationsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                recommendationsContent
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Recommendations")
    }

    @ViewBuilder
    private var recommendationsContent: some View {
        // Recommended Next Cards
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Next Cards")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            if recommendations.isEmpty {
                ContentUnavailableView(
                    "No Recommendations",
                    systemImage: "lightbulb",
                    description: Text("Add more cards to get personalized recommendations.")
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(recommendations) { card in
                        RecommendationRow(card: card, reason: reasonFor(card))
                        if card.id != recommendations.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(12)
            }
        }

        // Category Gaps
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Gaps")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                ForEach(categoryGaps, id: \.category) { gap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: gap.category.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(.orange)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(gap.category.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                Text("Your best: \(gap.currentRate)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(gap.potentialRate)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        }

                        // Show which card would earn this rate
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            Text("\(gap.potentialCardIssuer) \(gap.potentialCardName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.blue)
                            if gap.potentialCardFee > 0 {
                                Text("(\(gap.potentialCardFee.currencyFormatted)/yr)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("(No AF)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.leading, 36)
                    }
                    .frame(minHeight: 56)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if gap.category != categoryGaps.last?.category {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }

        // Optimization Tips
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Tips")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                TipRow(
                    icon: "dollarsign.circle",
                    title: "Maximize signup bonuses",
                    detail: "You have 2 cards with active bonuses to complete"
                )
                Divider().padding(.leading, 52)
                TipRow(
                    icon: "arrow.triangle.swap",
                    title: "Consolidate transfer partners",
                    detail: "Consider cards that transfer to your most-used airlines"
                )
                Divider().padding(.leading, 52)
                TipRow(
                    icon: "calendar",
                    title: "Annual fee optimization",
                    detail: "Review cards before annual fees hit to decide keep/cancel"
                )
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    private var cardBackgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
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

    private var categoryGaps: [(category: SpendCategory, currentRate: String, potentialRate: String, potentialCardName: String, potentialCardIssuer: String, potentialCardFee: Int)] {
        let userCardIds = Set(cardViewModel.userCards.map { $0.cardId })
        let userCards = feedService.cards.filter { userCardIds.contains($0.id) }

        var gaps: [(SpendCategory, String, String, String, String, Int)] = []

        for category in [SpendCategory.dining, .groceries, .gas, .travel, .streaming, .online] {
            let currentBest = userCards.compactMap { card in
                card.earningRates.first { $0.category == category }?.multiplier
            }.max() ?? 1.0

            // Find the actual best card in the full catalog
            let potentialBestCard = feedService.cards
                .filter { !userCardIds.contains($0.id) }
                .compactMap { card -> (CreditCard, Double)? in
                    guard let rate = card.earningRates.first(where: { $0.category == category }) else { return nil }
                    return (card, rate.multiplier)
                }
                .sorted { $0.1 > $1.1 }
                .first

            if let (bestCard, bestRate) = potentialBestCard, bestRate > currentBest {
                gaps.append((
                    category,
                    currentBest.multiplierFormatted,
                    bestRate.multiplierFormatted,
                    bestCard.name,
                    bestCard.issuer.displayName,
                    bestCard.annualFee
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
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                if card.annualFee > 0 {
                    Text(card.annualFee.currencyFormatted + "/yr")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No AF")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.green)
                }
            }

            Text(card.issuer.displayName)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(reason)
                .font(.system(size: 13))
                .foregroundStyle(.blue)
        }
        .frame(minHeight: 64)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 52)
    }
}

#Preview {
    NavigationStack {
        RecommendationsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
