import SwiftUI

struct WalletView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var walletVM = WalletViewModel()
    @State private var showSpendEntry = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                categoryPickerSection
                cardCarouselSection
                quickActionsSection
                activeBonusesSection
            }
            .padding()
        }
        .navigationTitle("Wallet")
        .sheet(isPresented: $showSpendEntry) {
            QuickSpendEntryView()
        }
    }

    // MARK: - Category Picker

    @ViewBuilder
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Card for...")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpendCategory.allCases) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                walletVM.selectedCategory = category
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                Text(category.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                walletVM.selectedCategory == category
                                    ? AnyShapeStyle(.blue)
                                    : AnyShapeStyle(.ultraThinMaterial)
                            )
                            .foregroundStyle(walletVM.selectedCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(category.displayName) category")
                        .accessibilityAddTraits(walletVM.selectedCategory == category ? .isSelected : [])
                    }
                }
            }
        }
    }

    // MARK: - Card Carousel

    @ViewBuilder
    private var cardCarouselSection: some View {
        let topCards = walletVM.topCards(
            for: walletVM.selectedCategory,
            userCards: cardViewModel.userCards,
            catalog: feedService.cards
        )

        if topCards.isEmpty {
            ContentUnavailableView(
                "No Cards in Wallet",
                systemImage: "creditcard",
                description: Text("Add cards to see recommendations.")
            )
            .frame(height: 200)
        } else {
            TabView {
                ForEach(Array(topCards.enumerated()), id: \.offset) { index, item in
                    CarouselCardView(
                        card: item.creditCard,
                        userCard: item.userCard,
                        rate: item.rate,
                        category: walletVM.selectedCategory,
                        rank: index + 1
                    )
                    .padding(.horizontal, 4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: topCards.count > 1 ? .automatic : .never))
            .frame(height: 220)
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                showSpendEntry = true
            } label: {
                QuickActionLabel(title: "Log Spend", icon: "dollarsign.circle.fill", color: .green)
            }
            .buttonStyle(.plain)

            NavigationLink {
                BenefitsView()
            } label: {
                QuickActionLabel(title: "Benefits", icon: "gift.fill", color: .purple)
            }
            .buttonStyle(.plain)

            NavigationLink {
                OffersView()
            } label: {
                QuickActionLabel(title: "Offers", icon: "tag.fill", color: .orange)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active Bonuses

    @ViewBuilder
    private var activeBonusesSection: some View {
        let bonusCards = cardViewModel.cardsWithActiveBonus
        if !bonusCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bonus Tracking")
                    .font(.headline)

                ForEach(bonusCards) { userCard in
                    if let card = feedService.card(for: userCard.cardId),
                       let bonus = userCard.signupBonusProgress {
                        BonusTrackingCard(
                            cardName: userCard.nickname ?? card.name,
                            bonus: bonus,
                            signupBonus: card.signupBonus,
                            onUpdateSpend: { newAmount in
                                cardViewModel.updateBonusSpend(for: userCard.id, amount: newAmount)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Carousel Card

struct CarouselCardView: View {
    let card: CreditCard
    let userCard: UserCard
    let rate: Double
    let category: SpendCategory
    let rank: Int

    var body: some View {
        VStack(spacing: 0) {
            // Card visual
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [issuerGradientStart(card.issuer), issuerGradientEnd(card.issuer)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)
                .overlay {
                    VStack {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                if rank == 1 {
                                    Text("BEST CARD")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Text(userCard.nickname ?? card.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(card.issuer.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(rate.multiplierFormatted)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }

                        Spacer()

                        HStack {
                            if let last4 = userCard.lastFourDigits {
                                Text("•••• \(last4)")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Text(card.network.displayName)
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding()
                }

                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(rank == 1 ? "Best card" : "Card \(rank)"), \(card.name), \(rate.multiplierFormatted) for \(category.displayName)")

            // Earning rates summary
            HStack(spacing: 16) {
                ForEach(card.earningRates.sorted { $0.multiplier > $1.multiplier }.prefix(3)) { rate in
                    VStack(spacing: 2) {
                        Text(rate.multiplier.multiplierFormatted)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text(rate.category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Bonus Tracking Card

struct BonusTrackingCard: View {
    let cardName: String
    let bonus: BonusProgress
    let signupBonus: SignupBonus?
    let onUpdateSpend: (Int) -> Void

    @State private var showSpendUpdate = false
    @State private var spendInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cardName)
                    .font(.subheadline.bold())
                Spacer()
                if bonus.completed {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else if bonus.isExpired {
                    Label("Expired", systemImage: "xmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                } else {
                    Text("\(bonus.daysRemaining)d left")
                        .font(.caption)
                        .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
                }
            }

            ProgressView(value: bonus.progress)
                .tint(bonus.completed ? .green : (bonus.daysRemaining < 30 ? .orange : .blue))

            HStack {
                Text("$\(bonus.spentSoFar.commaFormatted) / $\(bonus.targetSpend.commaFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let sb = signupBonus {
                    Text("\(sb.points.commaFormatted) \(sb.currency)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            if !bonus.completed && !bonus.isExpired {
                if showSpendUpdate {
                    HStack {
                        TextField("Total spent", text: $spendInput)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .textFieldStyle(.roundedBorder)

                        Button("Update") {
                            if let amount = Int(spendInput) {
                                onUpdateSpend(amount)
                                showSpendUpdate = false
                                spendInput = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Cancel") {
                            showSpendUpdate = false
                            spendInput = ""
                        }
                        .controlSize(.small)
                    }
                } else {
                    Button {
                        spendInput = "\(bonus.spentSoFar)"
                        showSpendUpdate = true
                    } label: {
                        Label("Update Spend", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Quick Action Label

struct QuickActionLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Quick Spend Entry Sheet

struct QuickSpendEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var amount = ""
    @State private var selectedCategory: SpendCategory = .dining
    @State private var selectedCardId: UUID?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amount)
                            .font(.title)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SpendCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Card") {
                    let activeCards = cardViewModel.userCards.filter { $0.isActive }
                    if activeCards.isEmpty {
                        Text("No active cards")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeCards) { userCard in
                            if let card = feedService.card(for: userCard.cardId) {
                                let rate = card.earningRates.first { $0.category == selectedCategory }?.multiplier
                                    ?? card.earningRates.first { $0.category == .other }?.multiplier
                                    ?? 1.0

                                Button {
                                    selectedCardId = userCard.id
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(userCard.nickname ?? card.name)
                                                .foregroundStyle(.primary)
                                            Text(card.issuer.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(rate.multiplierFormatted)
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                        if selectedCardId == userCard.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Note (optional)") {
                    TextField("What was this for?", text: $note)
                }

                if let selectedId = selectedCardId,
                   let userCard = cardViewModel.userCards.first(where: { $0.id == selectedId }),
                   userCard.signupBonusProgress != nil,
                   let spendAmount = Int(amount) {
                    Section {
                        Text("This will add $\(spendAmount) toward your signup bonus progress.")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Log Spend")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        logSpend()
                        dismiss()
                    }
                    .disabled(amount.isEmpty || selectedCardId == nil)
                }
            }
        }
    }

    private func logSpend() {
        guard let selectedId = selectedCardId,
              let spendAmount = Int(amount) else { return }

        // Update bonus progress if applicable
        if let index = cardViewModel.userCards.firstIndex(where: { $0.id == selectedId }),
           let bonus = cardViewModel.userCards[index].signupBonusProgress,
           !bonus.completed {
            let newTotal = bonus.spentSoFar + spendAmount
            cardViewModel.updateBonusSpend(for: selectedId, amount: newTotal)
        }
    }
}

// MARK: - Helpers

private func issuerGradientStart(_ issuer: Issuer) -> Color {
    switch issuer {
    case .chase: return .blue
    case .amex: return .indigo
    case .citi: return .cyan
    case .capitalOne: return .red
    case .barclays: return .teal
    case .usBank: return .purple
    case .wellsFargo: return .yellow
    case .bankOfAmerica: return .red
    case .discover: return .orange
    }
}

private func issuerGradientEnd(_ issuer: Issuer) -> Color {
    switch issuer {
    case .chase: return .blue.opacity(0.6)
    case .amex: return .purple
    case .citi: return .blue
    case .capitalOne: return .orange
    case .barclays: return .cyan
    case .usBank: return .indigo
    case .wellsFargo: return .red
    case .bankOfAmerica: return .pink
    case .discover: return .yellow
    }
}
