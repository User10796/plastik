import SwiftUI

struct OfferDetailView: View {
    @Environment(DataFeedService.self) private var feedService
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(\.dismiss) private var dismiss
    let offer: CardOffer

    @State private var showAddCard = false

    private var card: CreditCard? {
        feedService.card(for: offer.cardId)
    }

    private var alreadyHasCard: Bool {
        cardViewModel.userCards.contains { $0.cardId == offer.cardId }
    }

    private var churnRules: [ChurnRule] {
        guard let card else { return [] }
        return feedService.rules(for: card)
    }

    var body: some View {
        List {
            offerHeaderSection

            if let points = offer.bonusPoints, let currency = offer.bonusCurrency {
                Section("Bonus") {
                    LabeledContent("Points", value: "\(points.commaFormatted) \(currency)")
                    if let spend = offer.spendRequired {
                        LabeledContent("Spend Required", value: spend.currencyFormatted)
                    }
                    if let days = offer.timeframeDays {
                        LabeledContent("Timeframe", value: "\(days) days")
                    }
                    if let spend = offer.spendRequired, let days = offer.timeframeDays, days > 0 {
                        let perMonth = Double(spend) / (Double(days) / 30.0)
                        LabeledContent("Monthly Spend Needed", value: "$\(Int(perMonth).commaFormatted)")
                    }
                }
            }

            if let card {
                Section("Card Details") {
                    LabeledContent("Card", value: card.name)
                    LabeledContent("Issuer", value: card.issuer.displayName)
                    LabeledContent("Network", value: card.network.displayName)
                    LabeledContent("Annual Fee", value: card.annualFee > 0 ? card.annualFee.currencyFormatted : "No Fee")

                    if !card.earningRates.isEmpty {
                        DisclosureGroup("Earning Rates") {
                            ForEach(card.earningRates.sorted { $0.multiplier > $1.multiplier }) { rate in
                                HStack {
                                    Image(systemName: rate.category.icon)
                                        .frame(width: 20)
                                        .foregroundStyle(.blue)
                                    Text(rate.category.displayName)
                                    Spacer()
                                    Text(rate.multiplier.multiplierFormatted)
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
            }

            if !churnRules.isEmpty {
                Section("Churn Rules") {
                    ForEach(churnRules) { rule in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: rule.category.icon)
                                    .foregroundStyle(rule.ruleType == .applicationEligibility ? .blue : .orange)
                                Text(rule.name)
                                    .font(.subheadline.bold())
                            }
                            Text(rule.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 5/24 warning for Chase cards
                    if card?.issuer == .chase {
                        let count = cardViewModel.totalAnnualCards24Months
                        HStack {
                            Image(systemName: count < 5 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(count < 5 ? .green : .red)
                            Text("You are at \(count)/24")
                                .font(.caption)
                            Spacer()
                            Text(count < 5 ? "Eligible" : "Over 5/24")
                                .font(.caption.bold())
                                .foregroundStyle(count < 5 ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if let expDate = offer.expirationDate {
                Section("Expiration") {
                    LabeledContent("Expires", value: expDate.shortFormatted)
                    if let days = offer.daysUntilExpiration, days > 0 {
                        LabeledContent("Days Remaining", value: "\(days)")
                    }
                }
            }

            Section {
                if alreadyHasCard {
                    Label("This card is in your wallet", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        showAddCard = true
                    } label: {
                        Label("Add This Card to Wallet", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(offer.title)
        .sheet(isPresented: $showAddCard) {
            AddCardView()
        }
    }

    @ViewBuilder
    private var offerHeaderSection: some View {
        Section {
            VStack(spacing: 12) {
                Text(offer.title)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(offer.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let source = offer.source {
                    HStack {
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if offer.isTargeted {
                            Text("Targeted")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
