import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService

    // Selection state
    @State private var selectedIssuer: Issuer?
    @State private var selectedCardId: String?

    // Card details
    @State private var nickname = ""
    @State private var lastFour = ""
    @State private var openDate = Date()
    @State private var notes = ""

    // Card icon color
    @State private var cardIconColor = ""

    // Preset card icon colors - common credit card colors
    private let presetColors: [(name: String, hex: String)] = [
        ("Chase Blue", "004879"), ("Citi Blue", "003B70"), ("Sky", "00AEEF"),
        ("Navy", "1a1a2e"), ("Royal", "1a3d7c"), ("Cobalt", "0047AB"),
        ("Gold", "B4975A"), ("Rose Gold", "B76E79"), ("Platinum", "C0C0C0"),
        ("Silver", "A9A9A9"), ("Graphite", "4B4B4B"), ("Black", "1a1a1a"),
        ("Emerald", "1B5E3C"), ("Sage", "7C9A6E"), ("Teal", "008080"),
        ("Mint", "3EB489"), ("Forest", "003B2A"), ("Olive", "5C6B30"),
        ("Red", "CC2222"), ("Burgundy", "800020"), ("Rose", "C4536A"),
        ("Purple", "7B2D8B"), ("Plum", "5C2D82"), ("Orange", "E35205"),
    ]

    // Signup bonus tracking
    @State private var trackBonus = false
    @State private var bonusSpent = ""
    @State private var customBonusPoints = ""
    @State private var customBonusSpend = ""
    @State private var customBonusDays = "90"

    // Cards filtered by selected issuer
    private var cardsForIssuer: [CreditCard] {
        guard let issuer = selectedIssuer else { return [] }
        return feedService.cards
            .filter { $0.issuer == issuer }
            .sorted { $0.name < $1.name }
    }

    private var selectedCard: CreditCard? {
        guard let id = selectedCardId else { return nil }
        return feedService.card(for: id)
    }

    // Available issuers (those with cards in the feed + Custom)
    private var availableIssuers: [Issuer] {
        let issuersWithCards = Set(feedService.cards.map { $0.issuer })
        var issuers = Issuer.allCases.filter { issuersWithCards.contains($0) || $0 == .custom }
        // Sort alphabetically but keep Custom at end
        issuers.sort { lhs, rhs in
            if lhs == .custom { return false }
            if rhs == .custom { return true }
            return lhs.displayName < rhs.displayName
        }
        return issuers
    }

    // State for custom card warning
    @State private var showCustomWarning = false

    var body: some View {
        NavigationStack {
            Form {
                issuerSelectionSection

                if selectedIssuer != nil {
                    cardTypeSelectionSection
                }

                if canShowDetails {
                    cardDetailsSection
                    bonusTrackingSection
                    notesSection
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
                    Button("Add") { addCard() }
                        .disabled(!canShowDetails)
                }
            }
        }
    }

    // MARK: - Issuer Selection

    @ViewBuilder
    private var issuerSelectionSection: some View {
        Section {
            Picker("Select Issuer", selection: $selectedIssuer) {
                Text("Choose an issuer...").tag(nil as Issuer?)
                ForEach(availableIssuers) { issuer in
                    Text(issuer.displayName).tag(issuer as Issuer?)
                }
            }
            .onChange(of: selectedIssuer) { _, newIssuer in
                // Reset card selection when issuer changes
                selectedCardId = nil
                // Show warning for custom cards
                showCustomWarning = newIssuer == .custom
            }

            // Custom Card Warning
            if showCustomWarning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Custom Card Limitations")
                            .font(.headline)
                    }

                    Text("Custom cards are useful for personal tracking, but Plastik cannot automatically provide:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        LimitationRow(text: "Transfer partner information")
                        LimitationRow(text: "Bonus category tracking")
                        LimitationRow(text: "Signup bonus details")
                        LimitationRow(text: "Annual fee reminders")
                        LimitationRow(text: "\"Which card to use\" recommendations")
                    }
                    .padding(.leading, 4)

                    Text("For full features, use a card from our catalog.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Card Issuer")
        } footer: {
            if !showCustomWarning {
                Text("Select the bank or company that issued your card")
            }
        }
    }

    // MARK: - Card Type Selection

    @ViewBuilder
    private var cardTypeSelectionSection: some View {
        // For Custom cards, skip the card picker - they'll enter details manually
        if selectedIssuer == .custom {
            // Custom card - no catalog selection needed
            // Automatically set a custom card ID
            EmptyView()
                .onAppear {
                    selectedCardId = "custom-\(UUID().uuidString)"
                }
        } else {
            Section {
                if cardsForIssuer.isEmpty {
                    Text("No cards available for this issuer")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Select Card", selection: $selectedCardId) {
                        Text("Choose a card...").tag(nil as String?)
                        ForEach(cardsForIssuer) { card in
                            HStack {
                                Text(card.name)
                                if card.annualFee > 0 {
                                    Text("(\(card.annualFee.currencyFormatted)/yr)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(card.id as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif
                }
            } header: {
                if let issuer = selectedIssuer {
                    Text("\(issuer.displayName) Cards")
                }
            } footer: {
                if let card = selectedCard, let bonus = card.signupBonus {
                    Text("Current offer: \(bonus.points.commaFormatted) \(bonus.currency) after \(bonus.spendRequired.currencyFormatted) spend")
                }
            }
        }
    }

    // Check if we can show details (either selected a card or using custom)
    private var canShowDetails: Bool {
        selectedCard != nil || selectedIssuer == .custom
    }

    // MARK: - Card Details

    @ViewBuilder
    private var cardDetailsSection: some View {
        Section("Your Card Details") {
            TextField("Nickname (optional)", text: $nickname)
                .textContentType(.nickname)

            // Card icon color picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Card Icon Color (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                    ForEach(presetColors, id: \.hex) { preset in
                        Button {
                            cardIconColor = cardIconColor == preset.hex ? "" : preset.hex
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: preset.hex))
                                .frame(height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(cardIconColor == preset.hex ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)

            TextField("Last 4 digits", text: $lastFour)
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
                .onChange(of: lastFour) { _, newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        lastFour = String(newValue.prefix(4))
                    }
                    // Only allow numbers
                    lastFour = newValue.filter { $0.isNumber }
                }

            DatePicker("Date Opened", selection: $openDate, displayedComponents: .date)
        }
    }

    // MARK: - Bonus Tracking

    @ViewBuilder
    private var bonusTrackingSection: some View {
        Section {
            Toggle("Track Signup Bonus", isOn: $trackBonus)

            if trackBonus {
                if let bonus = selectedCard?.signupBonus {
                    // Show known bonus details
                    LabeledContent("Bonus") {
                        Text("\(bonus.points.commaFormatted) \(bonus.currency)")
                            .foregroundStyle(.blue)
                    }
                    LabeledContent("Spend Required") {
                        Text(bonus.spendRequired.currencyFormatted)
                    }
                    LabeledContent("Timeframe") {
                        Text("\(bonus.timeframeDays) days")
                    }

                    Divider()

                    HStack {
                        Text("Amount Spent So Far")
                        Spacer()
                        TextField("$0", text: $bonusSpent)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }

                    // Progress indicator
                    if let spent = Int(bonusSpent), spent > 0 {
                        let progress = min(Double(spent) / Double(bonus.spendRequired), 1.0)
                        ProgressView(value: progress) {
                            Text("\(Int(progress * 100))% complete")
                                .font(.caption)
                        }
                        .tint(progress >= 1.0 ? .green : .blue)
                    }
                } else {
                    // Custom bonus entry for cards without known bonus
                    TextField("Bonus Points", text: $customBonusPoints)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif

                    TextField("Spend Required ($)", text: $customBonusSpend)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif

                    TextField("Days to Complete", text: $customBonusDays)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                }
            }
        } header: {
            Text("Signup Bonus")
        } footer: {
            if trackBonus {
                Text("Track your progress toward meeting the minimum spend requirement")
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("Add any notes about this card...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    private func addCard() {
        guard let cardId = selectedCardId else { return }

        var bonusProgress: BonusProgress?
        if trackBonus {
            if let bonus = selectedCard?.signupBonus {
                // Use known bonus details
                let deadline = Calendar.current.date(
                    byAdding: .day,
                    value: bonus.timeframeDays,
                    to: openDate
                ) ?? openDate
                let spent = Int(bonusSpent) ?? 0
                bonusProgress = BonusProgress(
                    spentSoFar: spent,
                    targetSpend: bonus.spendRequired,
                    deadline: deadline,
                    completed: spent >= bonus.spendRequired
                )
            } else if let customSpend = Int(customBonusSpend),
                      let customDays = Int(customBonusDays) {
                // Use custom bonus details
                let deadline = Calendar.current.date(
                    byAdding: .day,
                    value: customDays,
                    to: openDate
                ) ?? openDate
                bonusProgress = BonusProgress(
                    spentSoFar: Int(bonusSpent) ?? 0,
                    targetSpend: customSpend,
                    deadline: deadline,
                    completed: false
                )
            }
        }

        let card = UserCard(
            cardId: cardId,
            nickname: nickname.isEmpty ? nil : nickname,
            lastFourDigits: lastFour.isEmpty ? nil : lastFour,
            openDate: openDate,
            signupBonusProgress: bonusProgress,
            isActive: true,
            notes: notes.isEmpty ? nil : notes,
            cardIconColor: cardIconColor.isEmpty ? nil : cardIconColor
        )

        viewModel.addCard(card)
        dismiss()
    }
}

// MARK: - Helper Views

struct LimitationRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle")
                .foregroundStyle(.red)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
