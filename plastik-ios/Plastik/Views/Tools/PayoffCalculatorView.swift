import SwiftUI

struct PayoffCalculatorView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var selectedStrategy: PayoffStrategy = .snowball
    @State private var showComparison = false
    @State private var extraMonthlyPayment: String = "200"
    @State private var payoffCards: [PayoffCard] = []
    @State private var currentPlan: PayoffPlan?
    @State private var comparisonPlans: [PayoffPlan] = []
    @State private var editingCard: PayoffCard?
    @State private var showAddCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Page header
                pageHeader

                // Strategy selection
                strategySection

                // Cards table
                cardsSection

                // Results or Comparison
                if showComparison {
                    comparisonSection
                } else if let plan = currentPlan {
                    resultsSection(plan: plan)
                    actionPlanSection(plan: plan)
                }

                // Tips
                tipsSection
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Payoff Calculator")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadCardsFromUserData()
            recalculate()
        }
        .onChange(of: selectedStrategy) { _, _ in
            showComparison = false
            recalculate()
        }
        .onChange(of: extraMonthlyPayment) { _, _ in
            recalculate()
        }
        .onChange(of: payoffCards) { _, _ in
            recalculate()
        }
        .sheet(item: $editingCard) { card in
            EditCardSheet(card: card) { updatedCard in
                if let index = payoffCards.firstIndex(where: { $0.id == updatedCard.id }) {
                    payoffCards[index] = updatedCard
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardSheet { newCard in
                payoffCards.append(newCard)
            }
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payoff Calculator")
                .font(.system(size: 24, weight: .semibold))

            Text("Create a personalized plan to become debt-free. Choose a strategy, see your projected timeline, and compare different approaches.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Strategy Section

    private var strategySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Strategy")
                .font(.system(size: 17, weight: .semibold))

            // Strategy pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PayoffStrategy.allCases) { strategy in
                        StrategyPill(
                            strategy: strategy,
                            isSelected: selectedStrategy == strategy && !showComparison
                        ) {
                            showComparison = false
                            selectedStrategy = strategy
                        }
                    }

                    // Compare button
                    Button {
                        showComparison = true
                        recalculateComparison()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.split.2x1")
                            Text("Compare")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(showComparison ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(showComparison ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 1)
            }

            // Strategy description card
            if !showComparison {
                StrategyDescriptionCard(strategy: selectedStrategy)
            }
        }
    }

    // MARK: - Cards Section

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Cards")
                .font(.system(size: 17, weight: .semibold))

            // Extra payment input
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Extra Monthly Payment")
                        .font(.system(size: 14, weight: .medium))

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $extraMonthlyPayment)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .frame(width: 100)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    #if os(iOS)
                    .background(Color(.tertiarySystemBackground))
                    #else
                    .background(Color(nsColor: .textBackgroundColor))
                    #endif
                    .cornerRadius(8)
                }

                Spacer()

                if let extra = Double(extraMonthlyPayment), extra > 0, let plan = currentPlan {
                    let minimumPlan = PayoffCalculator.calculateMinimumOnly(cards: payoffCards)
                    let savedInterest = minimumPlan.totalInterest - plan.totalInterest
                    let savedMonths = minimumPlan.totalMonths - plan.totalMonths

                    if savedMonths > 0 || savedInterest > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("You'll save")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("$\(Int(savedInterest).formatted()) & \(savedMonths) months")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .padding(16)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
            .cornerRadius(12)

            // Cards table
            if payoffCards.isEmpty {
                emptyCardsState
            } else {
                cardsTable
            }

            // Actions
            HStack(spacing: 12) {
                Button {
                    showAddCard = true
                } label: {
                    Label("Add Card", systemImage: "plus.circle")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)

                Spacer()

                // Summary
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Debt: $\(totalDebt.formatted())")
                        .font(.system(size: 14, weight: .medium))
                    Text("Total Minimum: $\(totalMinimum.formatted())/mo")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyCardsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No cards with balances")
                .font(.system(size: 17, weight: .medium))

            Text("Add your credit card balances to create a payoff plan.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddCard = true
            } label: {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }

    private var cardsTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 32, alignment: .center)
                Text("Card")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Balance")
                    .frame(width: 90, alignment: .trailing)
                Text("APR")
                    .frame(width: 70, alignment: .trailing)
                Text("Min Pay")
                    .frame(width: 80, alignment: .trailing)
                Spacer()
                    .frame(width: 50)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            #if os(iOS)
            .background(Color(.tertiarySystemBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            #endif

            Divider()

            // Rows
            let sortedCards = sortedPayoffCards
            ForEach(Array(sortedCards.enumerated()), id: \.element.id) { index, card in
                PayoffCardRow(
                    order: index + 1,
                    card: card,
                    isFirst: index == 0,
                    onEdit: { editingCard = card }
                )

                if index < sortedCards.count - 1 {
                    Divider().padding(.leading, 48)
                }
            }
        }
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Results Section

    // Grid columns for stat boxes - 2 columns on iOS, flexible on Mac
    private var statGridColumns: [GridItem] {
        #if os(iOS)
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        #else
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        #endif
    }

    @ViewBuilder
    private func resultsSection(plan: PayoffPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Payoff Plan")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Text("Using \(selectedStrategy.displayName)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Stat cards - using LazyVGrid for consistent sizing
            LazyVGrid(columns: statGridColumns, spacing: 12) {
                PayoffStatCard(
                    value: plan.debtFreeDate.formatted(.dateTime.month(.abbreviated).year()),
                    label: "Debt-Free Date",
                    sublabel: "\(plan.totalMonths) months",
                    color: .green
                )

                PayoffStatCard(
                    value: "$\(Int(plan.totalInterest).formatted())",
                    label: "Total Interest",
                    sublabel: nil,
                    color: .red
                )

                PayoffStatCard(
                    value: "$\(Int(plan.totalPaid).formatted())",
                    label: "Total Paid",
                    sublabel: nil,
                    color: .blue
                )

                if let firstMonth = plan.firstPayoffMonth, let firstCard = plan.firstPayoffCard {
                    PayoffStatCard(
                        value: "\(firstMonth) mo",
                        label: "First Payoff",
                        sublabel: firstCard,
                        color: .purple
                    )
                }
            }

            // Milestones timeline
            if !plan.payoffMilestones.isEmpty {
                milestonesView(milestones: plan.payoffMilestones)
            }
        }
    }

    private func milestonesView(milestones: [(month: Int, cardName: String, date: Date)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payoff Milestones")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                    HStack(spacing: 12) {
                        // Timeline dot
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .fixedSize()

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.cardName)
                                .font(.system(size: 15, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("\(milestone.date.formatted(.dateTime.month(.abbreviated).year())) • Month \(milestone.month)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("🎉")
                            .font(.system(size: 20))
                            .fixedSize()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if index < milestones.count - 1 {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 2, height: 16)
                            .padding(.leading, 31)
                    }
                }
            }
            .padding(.vertical, 8)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
            .cornerRadius(12)
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strategy Comparison")
                .font(.system(size: 17, weight: .semibold))

            // Comparison grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(comparisonPlans, id: \.strategy) { plan in
                        ComparisonCard(plan: plan) {
                            selectedStrategy = plan.strategy
                            showComparison = false
                        }
                    }

                    // Minimum only comparison
                    let minimumPlan = PayoffCalculator.calculateMinimumOnly(cards: payoffCards)
                    MinimumOnlyCard(plan: minimumPlan)
                }
                .padding(.horizontal, 1)
            }

            // Recommendation
            if let recommendation = generateRecommendation() {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 20))
                        .fixedSize()

                    Text(recommendation)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                #if os(iOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color(nsColor: .controlBackgroundColor))
                #endif
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Action Plan Section

    @ViewBuilder
    private func actionPlanSection(plan: PayoffPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Action Plan")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                let sortedCards = sortedPayoffCards
                let milestones = plan.payoffMilestones

                // Step 1: This month
                ActionStep(
                    stepNumber: 1,
                    title: "This Month",
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pay minimums on all cards except \(sortedCards.first?.name ?? ""):")
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)

                            ForEach(sortedCards.dropFirst(), id: \.id) { card in
                                HStack {
                                    Text("• \(card.name)")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                    Text("$\(Int(card.minimumPayment))")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.system(size: 14))
                            }

                            Divider().padding(.vertical, 8)

                            if let firstCard = sortedCards.first {
                                Text("Put everything extra toward \(firstCard.name):")
                                    .font(.system(size: 14, weight: .medium))
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Minimum: $\(Int(firstCard.minimumPayment))")
                                    Text("Extra: $\(extraPaymentValue)")
                                    Text("Total payment: $\(Int(firstCard.minimumPayment) + extraPaymentValue)")
                                        .fontWeight(.semibold)
                                }
                                .font(.system(size: 14))
                            }
                        }
                    }
                )

                // Future steps based on milestones
                ForEach(Array(milestones.prefix(3).enumerated()), id: \.offset) { index, milestone in
                    Divider()
                    ActionStep(
                        stepNumber: index + 2,
                        title: "Month \(milestone.month): \(milestone.cardName) Paid Off! 🎉",
                        content: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Roll \(milestone.cardName)'s payment to the next card in your plan.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    )
                }
            }
            .padding(16)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
            .cornerRadius(12)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips to Accelerate Your Payoff")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 12) {
                PayoffTip(
                    icon: "arrow.up.circle",
                    title: "Increase your extra payment",
                    detail: "Even $50 more per month can save hundreds in interest."
                )

                PayoffTip(
                    icon: "arrow.left.arrow.right.circle",
                    title: "Consider a balance transfer",
                    detail: "Transfer high-APR balances to a 0% intro APR card to save on interest."
                )

                PayoffTip(
                    icon: "calendar.badge.clock",
                    title: "Pay before statement close",
                    detail: "Paying early lowers your credit utilization and can improve your score."
                )

                PayoffTip(
                    icon: "arrow.clockwise.circle",
                    title: "Set up autopay",
                    detail: "Avoid late fees and protect your credit by enabling autopay for minimums."
                )
            }
            .padding(16)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
            .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    private var totalDebt: Int {
        Int(payoffCards.reduce(0) { $0 + $1.balance })
    }

    private var totalMinimum: Int {
        Int(payoffCards.reduce(0) { $0 + $1.minimumPayment })
    }

    private var extraPaymentValue: Int {
        Int(Double(extraMonthlyPayment) ?? 0)
    }

    private var sortedPayoffCards: [PayoffCard] {
        let cards = payoffCards.filter { $0.balance > 0 }
        switch selectedStrategy {
        case .snowball:
            return cards.sorted { $0.balance < $1.balance }
        case .avalanche:
            return cards.sorted { $0.apr > $1.apr }
        case .savvy:
            let threshold: Double = 1000
            let small = cards.filter { $0.balance <= threshold }.sorted { $0.balance < $1.balance }
            let large = cards.filter { $0.balance > threshold }.sorted { $0.apr > $1.apr }
            return small + large
        case .highestPayment:
            return cards.sorted { $0.minimumPayment > $1.minimumPayment }
        case .cashFlowIndex:
            return cards.sorted { $0.cashFlowIndex < $1.cashFlowIndex }
        }
    }

    private func loadCardsFromUserData() {
        // Load from user's cards with sample balances
        let userCardIds = Set(cardViewModel.userCards.map { $0.cardId })
        let userCreditCards = feedService.cards.filter { userCardIds.contains($0.id) }

        payoffCards = userCreditCards.map { card in
            // Generate sample data for demo purposes
            let balance = Double.random(in: 500...5000)
            let apr = Double.random(in: 15...25)
            let minPayment = max(25, balance * 0.02)

            return PayoffCard(
                cardId: card.id,
                name: card.name,
                issuer: card.issuer,
                balance: balance,
                apr: apr,
                minimumPayment: minPayment
            )
        }

        // If no cards, add sample data
        if payoffCards.isEmpty {
            payoffCards = [
                PayoffCard(name: "Chase Slate", issuer: .chase, balance: 850, apr: 22.9, minimumPayment: 25),
                PayoffCard(name: "Amazon Prime Visa", issuer: .chase, balance: 1200, apr: 19.9, minimumPayment: 35),
                PayoffCard(name: "Capital One Venture", issuer: .capitalOne, balance: 3500, apr: 17.9, minimumPayment: 85),
                PayoffCard(name: "Chase Sapphire", issuer: .chase, balance: 5200, apr: 21.9, minimumPayment: 125)
            ]
        }
    }

    private func recalculate() {
        let extra = Double(extraMonthlyPayment) ?? 0
        currentPlan = PayoffCalculator.calculate(
            cards: payoffCards,
            strategy: selectedStrategy,
            extraMonthlyPayment: extra
        )
    }

    private func recalculateComparison() {
        let extra = Double(extraMonthlyPayment) ?? 0
        comparisonPlans = PayoffCalculator.compareStrategies(
            cards: payoffCards,
            extraMonthlyPayment: extra
        )
    }

    private func generateRecommendation() -> String? {
        guard comparisonPlans.count >= 2 else { return nil }

        let snowball = comparisonPlans.first { $0.strategy == .snowball }
        let avalanche = comparisonPlans.first { $0.strategy == .avalanche }

        guard let s = snowball, let a = avalanche else { return nil }

        let interestDiff = abs(s.totalInterest - a.totalInterest)
        let monthDiff = abs((s.firstPayoffMonth ?? 0) - (a.firstPayoffMonth ?? 0))

        if interestDiff < 100 {
            return "Your APRs are similar, so Snowball makes sense for the motivation boost with minimal extra cost."
        } else if a.totalInterest < s.totalInterest - 200 {
            return "Avalanche saves you $\(Int(interestDiff)) more than Snowball. If savings matter most, go Avalanche."
        } else if monthDiff > 3 {
            return "Snowball gets you your first win \(monthDiff) months sooner. If motivation is key, go Snowball."
        }

        return "Both strategies work well for your debt profile. Choose based on whether you prefer quick wins (Snowball) or maximum savings (Avalanche)."
    }
}

// MARK: - Supporting Views

struct StrategyPill: View {
    let strategy: PayoffStrategy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: strategy.icon)
                Text(strategy.rawValue)
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12) // iOS: Increased for 44px touch target
            .frame(minHeight: 44) // iOS accessibility: 44px minimum touch target
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StrategyDescriptionCard: View {
    let strategy: PayoffStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: strategy.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(strategy.tagline)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }

            Text(strategy.description)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best for")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(strategy.bestFor)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Trade-off")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(strategy.tradeoff)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }
}

struct PayoffCardRow: View {
    let order: Int
    let card: PayoffCard
    let isFirst: Bool
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Order number
            ZStack {
                if isFirst {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                    Text("\(order)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(order)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 32)

            // Card info
            HStack(spacing: 10) {
                PayoffCardIcon(issuer: card.issuer, cardName: card.name)

                Text(card.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Balance
            Text("$\(Int(card.balance).formatted())")
                .font(.system(size: 14))
                .frame(width: 90, alignment: .trailing)

            // APR
            Text(String(format: "%.1f%%", card.apr))
                .font(.system(size: 14))
                .foregroundStyle(card.apr >= 20 ? .red : .secondary)
                .frame(width: 70, alignment: .trailing)

            // Min payment
            Text("$\(Int(card.minimumPayment))")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 50)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

struct PayoffStatCard: View {
    let value: String
    let label: String
    let sublabel: String?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let sublabel = sublabel {
                Text(sublabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ComparisonCard: View {
    let plan: PayoffPlan
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: plan.strategy.icon)
                Text(plan.strategy.displayName)
            }
            .font(.system(size: 15, weight: .semibold))

            Divider()

            // Stats
            VStack(spacing: 12) {
                ComparisonRow(label: "Debt-Free", value: plan.debtFreeDate.formatted(.dateTime.month(.abbreviated).year()))
                ComparisonRow(label: "Months", value: "\(plan.totalMonths)")
                ComparisonRow(label: "Interest", value: "$\(Int(plan.totalInterest).formatted())")
                ComparisonRow(label: "Total Paid", value: "$\(Int(plan.totalPaid).formatted())")
                if let firstMonth = plan.firstPayoffMonth {
                    ComparisonRow(label: "First Payoff", value: "\(firstMonth) months")
                }
            }

            Spacer()

            Button("Use This", action: onSelect)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(16)
        .frame(width: 180, height: 280)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ComparisonRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

struct MinimumOnlyCard: View {
    let plan: PayoffPlan

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "tortoise")
                Text("Minimum Only")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 12) {
                ComparisonRow(label: "Debt-Free", value: plan.debtFreeDate.formatted(.dateTime.month(.abbreviated).year()))
                ComparisonRow(label: "Months", value: "\(plan.totalMonths)")
                ComparisonRow(label: "Interest", value: "$\(Int(plan.totalInterest).formatted())")
                ComparisonRow(label: "Total Paid", value: "$\(Int(plan.totalPaid).formatted())")
            }

            Spacer()

            Text("😰 Not recommended")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 180, height: 280)
        #if os(iOS)
        .background(Color(.tertiarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

struct ActionStep<Content: View>: View {
    let stepNumber: Int
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)
                    Text("\(stepNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .fixedSize()

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            content()
                .padding(.leading, 38)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

struct PayoffTip: View {
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
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 52)
    }
}

// MARK: - Payoff Card Icon

struct PayoffCardIcon: View {
    let issuer: Issuer?
    let cardName: String

    private var theme: IssuerTheme {
        if let issuer = issuer {
            return IssuerGradients.theme(for: issuer, cardName: cardName)
        }
        return IssuerGradients.unknown
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.gradient)

            if let issuer = issuer {
                Text(String(issuer.displayName.prefix(1)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.logoColor)
            }
        }
        .frame(width: 36, height: 23)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Edit Card Sheet

struct EditCardSheet: View {
    let card: PayoffCard
    let onSave: (PayoffCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var balance: String
    @State private var apr: String
    @State private var minimumPayment: String

    init(card: PayoffCard, onSave: @escaping (PayoffCard) -> Void) {
        self.card = card
        self.onSave = onSave
        _balance = State(initialValue: String(format: "%.0f", card.balance))
        _apr = State(initialValue: String(format: "%.1f", card.apr))
        _minimumPayment = State(initialValue: String(format: "%.0f", card.minimumPayment))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    LabeledContent("Card") {
                        Text(card.name)
                    }
                }

                Section("Balance & Payments") {
                    HStack {
                        Text("Balance")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $balance)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    HStack {
                        Text("APR")
                        Spacer()
                        TextField("0", text: $apr)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Minimum Payment")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $minimumPayment)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            .navigationTitle("Edit \(card.name)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = card
                        updated.balance = Double(balance) ?? card.balance
                        updated.apr = Double(apr) ?? card.apr
                        updated.minimumPayment = Double(minimumPayment) ?? card.minimumPayment
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 300)
        #endif
    }
}

// MARK: - Add Card Sheet

struct AddCardSheet: View {
    let onAdd: (PayoffCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var balance: String = ""
    @State private var apr: String = ""
    @State private var minimumPayment: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Information") {
                    TextField("Card Name", text: $name)

                    HStack {
                        Text("Balance")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $balance)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    HStack {
                        Text("APR")
                        Spacer()
                        TextField("0", text: $apr)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Minimum Payment")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $minimumPayment)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            .navigationTitle("Add Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let card = PayoffCard(
                            name: name,
                            balance: Double(balance) ?? 0,
                            apr: Double(apr) ?? 0,
                            minimumPayment: Double(minimumPayment) ?? 25
                        )
                        onAdd(card)
                        dismiss()
                    }
                    .disabled(name.isEmpty || balance.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 300)
        #endif
    }
}

#Preview {
    NavigationStack {
        PayoffCalculatorView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
