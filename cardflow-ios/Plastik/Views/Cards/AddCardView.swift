import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var selectedCardId: String?
    @State private var nickname = ""
    @State private var lastFour = ""
    @State private var openDate = Date()
    @State private var trackBonus = false
    @State private var bonusSpent = ""
    @State private var notes = ""

    @State private var searchText = ""

    private var filteredCards: [CreditCard] {
        if searchText.isEmpty {
            return feedService.cards
        }
        return feedService.cards.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.issuer.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedCard: CreditCard? {
        guard let id = selectedCardId else { return nil }
        return feedService.card(for: id)
    }

    var body: some View {
        NavigationStack {
            Form {
                cardSelectionSection
                if selectedCard != nil {
                    personalInfoSection
                    if selectedCard?.signupBonus != nil {
                        bonusTrackingSection
                    }
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
                        .disabled(selectedCardId == nil)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var cardSelectionSection: some View {
        Section("Select Card") {
            TextField("Search cards...", text: $searchText)

            ForEach(filteredCards) { card in
                Button {
                    selectedCardId = card.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(card.issuer.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if card.annualFee > 0 {
                            Text(card.annualFee.currencyFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if selectedCardId == card.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var personalInfoSection: some View {
        Section("Card Details") {
            TextField("Nickname (optional)", text: $nickname)
            TextField("Last 4 digits", text: $lastFour)
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
            DatePicker("Date Opened", selection: $openDate, displayedComponents: .date)
        }
    }

    @ViewBuilder
    private var bonusTrackingSection: some View {
        if let bonus = selectedCard?.signupBonus {
            Section("Signup Bonus") {
                Toggle("Track Signup Bonus", isOn: $trackBonus)

                if trackBonus {
                    LabeledContent("Bonus", value: "\(bonus.points.commaFormatted) \(bonus.currency)")
                    LabeledContent("Spend Required", value: bonus.spendRequired.currencyFormatted)
                    LabeledContent("Timeframe", value: "\(bonus.timeframeDays) days")

                    TextField("Amount Spent So Far", text: $bonusSpent)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    private func addCard() {
        guard let cardId = selectedCardId else { return }

        var bonusProgress: BonusProgress?
        if trackBonus, let bonus = selectedCard?.signupBonus {
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
        }

        let card = UserCard(
            cardId: cardId,
            nickname: nickname.isEmpty ? nil : nickname,
            lastFourDigits: lastFour.isEmpty ? nil : lastFour,
            openDate: openDate,
            signupBonusProgress: bonusProgress,
            isActive: true,
            notes: notes.isEmpty ? nil : notes
        )

        viewModel.addCard(card)
        dismiss()
    }
}
