import SwiftUI

struct CardDetailView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let card: CreditCard

    // MARK: - Editable State

    @State private var name: String
    @State private var issuer: String
    @State private var holder: String
    @State private var annualFee: Double
    @State private var apr: Double
    @State private var currentBalance: Double
    @State private var creditLimit: Double
    @State private var openDate: Date
    @State private var anniversaryDate: Date
    @State private var notes: String
    @State private var pointsType: String
    @State private var churnEligible: Date?
    @State private var feeDecision: String
    @State private var retentionOffer: String

    // Signup bonus state
    @State private var hasSignupBonus: Bool
    @State private var bonusTarget: Double
    @State private var bonusCurrent: Double
    @State private var bonusReward: Double
    @State private var bonusRewardType: String
    @State private var bonusDeadline: Date?
    @State private var bonusCompleted: Bool

    // Spending caps
    @State private var spendingCaps: [SpendingCap]

    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(card: CreditCard) {
        self.card = card

        let isoFormatter = Formatters.dateISO

        _name = State(initialValue: card.name)
        _issuer = State(initialValue: card.issuer)
        _holder = State(initialValue: card.holder)
        _annualFee = State(initialValue: card.annualFee)
        _apr = State(initialValue: card.apr)
        _currentBalance = State(initialValue: card.currentBalance)
        _creditLimit = State(initialValue: card.creditLimit)
        _openDate = State(initialValue: isoFormatter.date(from: card.openDate) ?? Date())
        _anniversaryDate = State(initialValue: isoFormatter.date(from: card.anniversaryDate) ?? Date())
        _notes = State(initialValue: card.notes)
        _pointsType = State(initialValue: card.pointsType ?? "")
        _feeDecision = State(initialValue: card.feeDecision ?? "")
        _retentionOffer = State(initialValue: card.retentionOffer ?? "")
        _spendingCaps = State(initialValue: card.spendingCaps)

        if let churnStr = card.churnEligible, let churnDate = isoFormatter.date(from: churnStr) {
            _churnEligible = State(initialValue: churnDate)
        } else {
            _churnEligible = State(initialValue: nil)
        }

        if let bonus = card.signupBonus {
            _hasSignupBonus = State(initialValue: true)
            _bonusTarget = State(initialValue: bonus.target)
            _bonusCurrent = State(initialValue: bonus.current)
            _bonusReward = State(initialValue: bonus.reward)
            _bonusRewardType = State(initialValue: bonus.rewardType)
            _bonusCompleted = State(initialValue: bonus.completed)
            if let dl = bonus.deadline, let dlDate = isoFormatter.date(from: dl) {
                _bonusDeadline = State(initialValue: dlDate)
            } else {
                _bonusDeadline = State(initialValue: nil)
            }
        } else {
            _hasSignupBonus = State(initialValue: false)
            _bonusTarget = State(initialValue: 0)
            _bonusCurrent = State(initialValue: 0)
            _bonusReward = State(initialValue: 0)
            _bonusRewardType = State(initialValue: "points")
            _bonusCompleted = State(initialValue: false)
            _bonusDeadline = State(initialValue: nil)
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            cardInfoSection
            financialsSection
            datesSection
            bonusSection
            spendingCapsSection
            churningSection
            notesSection
            deleteSection
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.background)
        .navigationTitle("\(issuer) \(name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveCard() }
                    .foregroundColor(ColorTheme.gold)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Sections

    private var cardInfoSection: some View {
        Section {
            styledTextField("Card Name", text: $name)
            styledTextField("Issuer", text: $issuer)

            Picker("Holder", selection: $holder) {
                ForEach(store.holders, id: \.self) { h in
                    Text(h).tag(h)
                }
            }
            .listRowBackground(ColorTheme.cardBg)
            .foregroundColor(ColorTheme.textPrimary)

            styledTextField("Points Type", text: $pointsType, prompt: "e.g. Ultimate Rewards")
        } header: {
            Text("Card Info")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var financialsSection: some View {
        Section {
            currencyField("Annual Fee", value: $annualFee)
            percentField("APR", value: $apr)
            currencyField("Current Balance", value: $currentBalance)
            currencyField("Credit Limit", value: $creditLimit)
        } header: {
            Text("Financials")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var datesSection: some View {
        Section {
            styledDatePicker("Open Date", selection: $openDate)
            styledDatePicker("Anniversary Date", selection: $anniversaryDate)
        } header: {
            Text("Dates")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var bonusSection: some View {
        Section {
            Toggle("Signup Bonus", isOn: $hasSignupBonus)
                .listRowBackground(ColorTheme.cardBg)
                .foregroundColor(ColorTheme.textPrimary)
                .tint(ColorTheme.gold)

            if hasSignupBonus {
                currencyField("Spend Target", value: $bonusTarget)
                currencyField("Current Spend", value: $bonusCurrent)

                HStack {
                    Text("Reward")
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    TextField("0", value: $bonusReward, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(ColorTheme.textPrimary)
                }
                .listRowBackground(ColorTheme.cardBg)

                Picker("Reward Type", selection: $bonusRewardType) {
                    Text("Points").tag("points")
                    Text("Miles").tag("miles")
                    Text("Cash Back").tag("cashback")
                    Text("Statement Credit").tag("credit")
                }
                .listRowBackground(ColorTheme.cardBg)
                .foregroundColor(ColorTheme.textPrimary)

                if let deadline = bonusDeadline {
                    styledDatePicker("Deadline", selection: Binding(
                        get: { deadline },
                        set: { bonusDeadline = $0 }
                    ))
                } else {
                    Button("Set Deadline") {
                        bonusDeadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                    }
                    .listRowBackground(ColorTheme.cardBg)
                    .foregroundColor(ColorTheme.gold)
                }

                Toggle("Completed", isOn: $bonusCompleted)
                    .listRowBackground(ColorTheme.cardBg)
                    .foregroundColor(ColorTheme.textPrimary)
                    .tint(ColorTheme.green)

                if !bonusCompleted && bonusTarget > 0 {
                    let progress = min(bonusCurrent / bonusTarget, 1.0)
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progress)
                            .tint(ColorTheme.gold)
                        Text("\(Formatters.formatCurrency(bonusCurrent)) / \(Formatters.formatCurrency(bonusTarget))")
                            .font(.caption)
                            .foregroundColor(ColorTheme.goldLight)
                    }
                    .listRowBackground(ColorTheme.cardBg)
                }
            }
        } header: {
            Text("Signup Bonus")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var spendingCapsSection: some View {
        Section {
            if spendingCaps.isEmpty {
                Text("No spending caps")
                    .foregroundColor(ColorTheme.textMuted)
                    .listRowBackground(ColorTheme.cardBg)
            } else {
                ForEach(spendingCaps) { cap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cap.category)
                                .foregroundColor(ColorTheme.textPrimary)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(String(format: "%.1f", cap.rate))x")
                                .foregroundColor(ColorTheme.gold)
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("Cap: \(Formatters.formatCurrency(cap.cap))")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)
                            Spacer()
                            Text("Spent: \(Formatters.formatCurrency(cap.currentSpend))")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textMuted)
                        }
                        if cap.cap > 0 {
                            ProgressView(value: min(cap.currentSpend / cap.cap, 1.0))
                                .tint(cap.currentSpend >= cap.cap ? ColorTheme.red : ColorTheme.green)
                        }
                    }
                    .listRowBackground(ColorTheme.cardBg)
                }
            }
        } header: {
            Text("Spending Caps")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var churningSection: some View {
        Section {
            if let churnDate = churnEligible {
                styledDatePicker("Churn Eligible", selection: Binding(
                    get: { churnDate },
                    set: { churnEligible = $0 }
                ))
                Button("Remove Churn Date") { churnEligible = nil }
                    .listRowBackground(ColorTheme.cardBg)
                    .foregroundColor(ColorTheme.red)
                    .font(.caption)
            } else {
                Button("Set Churn Eligible Date") {
                    churnEligible = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
                }
                .listRowBackground(ColorTheme.cardBg)
                .foregroundColor(ColorTheme.gold)
            }

            styledTextField("Fee Decision", text: $feeDecision, prompt: "e.g. Keep, Cancel, Downgrade")
            styledTextField("Retention Offer", text: $retentionOffer, prompt: "e.g. $50 statement credit")
        } header: {
            Text("Churning & Retention")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .foregroundColor(ColorTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .listRowBackground(ColorTheme.cardBg)
        } header: {
            Text("Notes")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Card", systemImage: "trash")
                        .foregroundColor(ColorTheme.red)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .listRowBackground(ColorTheme.cardBg)
            .confirmationDialog("Delete this card?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.deleteCard(card)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Reusable Field Helpers

    private func styledTextField(_ label: String, text: Binding<String>, prompt: String? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField(prompt ?? label, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func currencyField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField("$0.00", value: value, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func percentField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField("0.00", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
            Text("%")
                .foregroundColor(ColorTheme.textMuted)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func styledDatePicker(_ label: String, selection: Binding<Date>) -> some View {
        DatePicker(label, selection: selection, displayedComponents: .date)
            .foregroundColor(ColorTheme.textSecondary)
            .tint(ColorTheme.gold)
            .listRowBackground(ColorTheme.cardBg)
    }

    // MARK: - Save

    private func saveCard() {
        let iso = Formatters.dateISO

        var updated = card
        updated.name = name
        updated.issuer = issuer
        updated.holder = holder
        updated.annualFee = annualFee
        updated.apr = apr
        updated.currentBalance = currentBalance
        updated.creditLimit = creditLimit
        updated.openDate = iso.string(from: openDate)
        updated.anniversaryDate = iso.string(from: anniversaryDate)
        updated.notes = notes
        updated.pointsType = pointsType.isEmpty ? nil : pointsType
        updated.feeDecision = feeDecision.isEmpty ? nil : feeDecision
        updated.retentionOffer = retentionOffer.isEmpty ? nil : retentionOffer
        updated.spendingCaps = spendingCaps

        if let churnDate = churnEligible {
            updated.churnEligible = iso.string(from: churnDate)
        } else {
            updated.churnEligible = nil
        }

        if hasSignupBonus {
            var bonus = SignupBonus()
            bonus.target = bonusTarget
            bonus.current = bonusCurrent
            bonus.reward = bonusReward
            bonus.rewardType = bonusRewardType
            bonus.completed = bonusCompleted
            if let dl = bonusDeadline {
                bonus.deadline = iso.string(from: dl)
            }
            updated.signupBonus = bonus
        } else {
            updated.signupBonus = nil
        }

        store.updateCard(updated)
        dismiss()
    }
}
