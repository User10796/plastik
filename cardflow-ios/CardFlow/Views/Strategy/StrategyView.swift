import SwiftUI

struct StrategyView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("Strategy", selection: $selectedTab) {
                    Text("Churn").tag(0)
                    Text("Evaluate").tag(1)
                    Text("Tips").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0:
                            churnOpportunitiesView
                        case 1:
                            evaluateCardView
                        case 2:
                            recommendationsView
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .background(ColorTheme.background)
            .navigationTitle("Strategy")
        }
    }

    // MARK: - Churn Opportunities

    private var churnEligibleCards: [CreditCard] {
        store.cards.filter { $0.churnEligible != nil }
    }

    @ViewBuilder
    private var churnOpportunitiesView: some View {
        if churnEligibleCards.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(ColorTheme.textMuted)
                Text("No Churn Opportunities")
                    .font(.headline)
                    .foregroundColor(ColorTheme.textPrimary)
                Text("Cards with churn eligible dates will appear here.")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(ColorTheme.cardBg)
            .cornerRadius(16)
        } else {
            ForEach(churnEligibleCards) { card in
                let days = Formatters.daysUntil(card.churnEligible ?? "") ?? 0
                let isEligibleNow = days <= 0

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(card.issuer) \(card.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                            Text(card.holder)
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        Spacer()

                        if isEligibleNow {
                            Text("ELIGIBLE")
                                .font(.caption.weight(.bold))
                                .foregroundColor(ColorTheme.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(ColorTheme.green.opacity(0.15))
                                .cornerRadius(8)
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(days) days")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(ColorTheme.gold)
                                Text(Formatters.formatDate(card.churnEligible ?? ""))
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textMuted)
                            }
                        }
                    }

                    // Potential bonus value
                    if let bonus = card.signupBonus {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Potential Bonus")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textMuted)
                                Text("\(Int(bonus.reward)) \(bonus.rewardType)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(ColorTheme.gold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Spend Required")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textMuted)
                                Text(Formatters.formatCurrency(bonus.target))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(ColorTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEligibleNow ? ColorTheme.green.opacity(0.5) : ColorTheme.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Evaluate Card

    @State private var evaluateMode = 0  // 0 = popular, 1 = custom
    @State private var selectedPopularCard = 0
    @State private var customCardName = ""
    @State private var customIssuer = ""
    @State private var customAnnualFee = ""
    @State private var customSignupBonus = ""
    @State private var customSpendRequirement = ""
    @State private var isAnalyzing = false
    @State private var analysisResult: [String: Any]?
    @State private var analysisError: String?

    private var popularCards: [(name: String, info: String)] {
        [
            ("Chase Sapphire Preferred", "Chase Sapphire Preferred: $95 AF, 60K UR signup bonus after $4K in 3 months, 3x dining/streaming, 2x travel, 1x everything else"),
            ("Chase Sapphire Reserve", "Chase Sapphire Reserve: $550 AF ($300 travel credit), 60K UR signup bonus after $4K in 3 months, 3x travel/dining, 10x hotels/car via portal"),
            ("Amex Gold", "Amex Gold: $250 AF ($120 dining + $120 Uber credits), 60K MR signup bonus after $6K in 6 months, 4x restaurants/groceries, 3x flights"),
            ("Amex Platinum", "Amex Platinum: $695 AF (multiple credits), 80K MR signup bonus after $8K in 6 months, 5x flights/hotels via Amex Travel"),
            ("Capital One Venture X", "Capital One Venture X: $395 AF ($300 travel portal credit), 75K miles signup bonus after $4K in 3 months, 2x everything, 10x hotels/car via portal"),
            ("Citi Custom Cash", "Citi Custom Cash: $0 AF, $200 cash back after $1.5K in 6 months, 5% on top spend category (up to $500/month)"),
            ("Chase Ink Business Preferred", "Chase Ink Business Preferred: $95 AF, 100K UR after $8K in 3 months, 3x travel/shipping/internet/advertising"),
            ("Amex Blue Business Plus", "Amex Blue Business Plus: $0 AF, 15K MR after $3K in 3 months, 2x on first $50K/year"),
        ]
    }

    @ViewBuilder
    private var evaluateCardView: some View {
        VStack(spacing: 16) {
            if store.apiKey.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ColorTheme.gold)
                    Text("Set your Anthropic API key in Settings to evaluate cards.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.gold)
                }
                .padding()
                .background(Color(red: 95/255, green: 63/255, blue: 31/255).opacity(0.5))
                .cornerRadius(12)
            }

            Picker("Mode", selection: $evaluateMode) {
                Text("Popular Cards").tag(0)
                Text("Custom").tag(1)
            }
            .pickerStyle(.segmented)

            if evaluateMode == 0 {
                // Popular cards picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a Card")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)

                    Picker("Card", selection: $selectedPopularCard) {
                        ForEach(Array(popularCards.enumerated()), id: \.offset) { index, card in
                            Text(card.name).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ColorTheme.gold)
                    .padding(12)
                    .background(ColorTheme.surfaceBg)
                    .cornerRadius(10)
                }
            } else {
                // Custom card input
                VStack(spacing: 12) {
                    customField("Card Name", text: $customCardName, placeholder: "e.g., Chase Sapphire Preferred")
                    customField("Issuer", text: $customIssuer, placeholder: "e.g., Chase")
                    customField("Annual Fee", text: $customAnnualFee, placeholder: "e.g., 95", keyboard: .decimalPad)
                    customField("Signup Bonus", text: $customSignupBonus, placeholder: "e.g., 60000 Ultimate Rewards points")
                    customField("Spend Requirement", text: $customSpendRequirement, placeholder: "e.g., $4000 in 3 months")
                }
            }

            // Analyze Button
            Button(action: analyzeCard) {
                HStack(spacing: 8) {
                    if isAnalyzing {
                        ProgressView()
                            .tint(ColorTheme.background)
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Evaluate Card")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.apiKey.isEmpty || isAnalyzing ? ColorTheme.surfaceBg : ColorTheme.blue)
                .foregroundColor(store.apiKey.isEmpty || isAnalyzing ? ColorTheme.textMuted : .white)
                .cornerRadius(12)
            }
            .disabled(store.apiKey.isEmpty || isAnalyzing)

            if let error = analysisError {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ColorTheme.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(ColorTheme.red)
                }
                .padding()
                .background(Color(red: 79/255, green: 31/255, blue: 31/255).opacity(0.5))
                .cornerRadius(12)
            }

            if let result = analysisResult {
                CardAnalysisView(analysis: result)
            }
        }
    }

    @ViewBuilder
    private func customField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundColor(ColorTheme.textPrimary)
                .padding(10)
                .background(ColorTheme.surfaceBg)
                .cornerRadius(8)
        }
    }

    // MARK: - Recommendations

    @ViewBuilder
    private var recommendationsView: some View {
        VStack(spacing: 16) {
            // 5/24 Status
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(store.canApplyChase ? ColorTheme.green : ColorTheme.red)
                    Text("Chase 5/24 Status")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)
                }

                HStack {
                    Text("Current Count")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Text("\(store.fiveOverTwentyFour)/24")
                        .font(.title3.weight(.bold))
                        .foregroundColor(store.canApplyChase ? ColorTheme.green : ColorTheme.red)
                }

                if store.canApplyChase {
                    let slotsRemaining = 5 - store.fiveOverTwentyFour
                    Text("You have \(slotsRemaining) slot\(slotsRemaining == 1 ? "" : "s") remaining. Prioritize Chase cards before other issuers.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.green)
                } else {
                    Text("You are over 5/24. Focus on issuers that do not use 5/24: Amex, Capital One, Barclays, Citi.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.gold)
                }
            }
            .padding()
            .background(ColorTheme.cardBg)
            .cornerRadius(12)

            // Upcoming Fee Dates
            let upcomingFees = store.upcomingAnniversaries.prefix(5)
            if !upcomingFees.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(ColorTheme.gold)
                        Text("Upcoming Fee Decisions")
                            .font(.headline)
                            .foregroundColor(ColorTheme.textPrimary)
                    }

                    ForEach(upcomingFees) { card in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(card.issuer) \(card.name)")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.textPrimary)
                                if let days = Formatters.daysUntil(card.anniversaryDate) {
                                    Text(days > 0 ? "\(days) days away" : "Past due")
                                        .font(.caption)
                                        .foregroundColor(days <= 30 ? ColorTheme.red : ColorTheme.textMuted)
                                }
                            }
                            Spacer()
                            Text(Formatters.formatCurrency(card.annualFee))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.gold)
                        }
                    }

                    Text("Call retention before cancelling. Many cards offer statement credits or reduced fees.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }

            // Points Balances
            if !store.pointsBalances.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(ColorTheme.gold)
                        Text("Points Balances")
                            .font(.headline)
                            .foregroundColor(ColorTheme.textPrimary)
                    }

                    ForEach(store.pointsBalances.sorted(by: { $0.value > $1.value }), id: \.key) { type, balance in
                        HStack {
                            Text(type)
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textPrimary)
                            Spacer()
                            Text("\(Int(balance)) pts")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(ColorTheme.gold)
                        }
                    }

                    Text("Consider transfer partner sweet spots for maximum value. Aim for 1.5 cpp or higher.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }

            // General Tips
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(ColorTheme.gold)
                    Text("General Tips")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)
                }

                tipRow(icon: "creditcard.fill", text: "Space applications 3+ months apart to avoid velocity denials.")
                tipRow(icon: "clock.fill", text: "Apply for business cards to preserve 5/24 slots.")
                tipRow(icon: "arrow.triangle.2.circlepath", text: "Set calendar reminders 30 days before annual fees hit.")
                tipRow(icon: "dollarsign.circle.fill", text: "Use manufactured spending wisely to meet signup bonuses.")
                tipRow(icon: "phone.fill", text: "Always call retention before downgrading or cancelling.")
            }
            .padding()
            .background(ColorTheme.cardBg)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(ColorTheme.blue)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
        }
    }

    // MARK: - Actions

    private func analyzeCard() {
        guard !store.apiKey.isEmpty else { return }

        isAnalyzing = true
        analysisError = nil
        analysisResult = nil

        let cardInfo: String
        if evaluateMode == 0 {
            cardInfo = popularCards[selectedPopularCard].info
        } else {
            cardInfo = """
            \(customCardName) by \(customIssuer)
            Annual Fee: $\(customAnnualFee)
            Signup Bonus: \(customSignupBonus)
            Spend Requirement: \(customSpendRequirement)
            """
        }

        let context = """
        Current cards: \(store.cards.count)
        5/24 status: \(store.fiveOverTwentyFour)/24
        Current issuers: \(Set(store.cards.map { $0.issuer }).joined(separator: ", "))
        Total annual fees: \(Formatters.formatCurrency(store.totalAnnualFees))
        Points balances: \(store.pointsBalances.map { "\($0.key): \(Int($0.value))" }.joined(separator: ", "))
        Account holders: \(store.holders.joined(separator: ", "))
        """

        let service = AnthropicService(apiKey: store.apiKey)

        Task {
            do {
                let result = try await service.analyzeCard(cardInfo, context: context)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}
